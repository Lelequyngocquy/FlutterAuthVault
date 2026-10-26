package services

import (
	"testing"
	"time"

	"secure_auth_vault_backend/internal/config"
	"secure_auth_vault_backend/internal/models"
	"secure_auth_vault_backend/internal/store"
)

func setupTestService() (*AuthService, *store.MemoryStore) {
	cfg := &config.Config{
		Port:               "8080",
		JWTSecret:          []byte("test_secret_key_1234567890"),
		AccessTokenTTL:     2 * time.Second,
		RefreshTokenTTL:    1 * time.Hour,
		ChallengeTTL:       5 * time.Second,
		RefreshDelayMillis: 0,
	}
	s := store.NewMemoryStore()
	svc := NewAuthService(cfg, s)
	return svc, s
}

func TestAuthenticateUser_PasswordAndPIN(t *testing.T) {
	svc, _ := setupTestService()

	// Valid password
	user, err := svc.AuthenticateUser(&models.LoginRequest{
		Username: "admin",
		Password: "admin123",
	})
	if err != nil || user.Username != "admin" {
		t.Fatalf("Expected admin login success, got err: %v", err)
	}

	// Valid PIN (fallback)
	userByPIN, err := svc.AuthenticateUser(&models.LoginRequest{
		Username: "admin",
		PIN:      "123456",
	})
	if err != nil || userByPIN.Username != "admin" {
		t.Fatalf("Expected admin login via PIN success, got err: %v", err)
	}

	// Invalid password
	_, err = svc.AuthenticateUser(&models.LoginRequest{
		Username: "admin",
		Password: "wrong_password",
	})
	if err == nil {
		t.Fatal("Expected error for wrong password, got nil")
	}
}

func TestGenerateAndParseToken(t *testing.T) {
	svc, s := setupTestService()
	user, _ := s.GetUserByUsername("admin")

	tokens, err := svc.GenerateTokenPair(user, "test-device-uuid")
	if err != nil {
		t.Fatalf("GenerateTokenPair failed: %v", err)
	}

	if tokens.AccessToken == "" || tokens.RefreshToken == "" {
		t.Fatal("Tokens should not be empty")
	}

	claims, err := svc.ParseToken(tokens.AccessToken)
	if err != nil {
		t.Fatalf("ParseToken failed: %v", err)
	}

	if claims.Username != "admin" || claims.Role != "SECURITY_OFFICER" {
		t.Fatalf("Claims mismatch: got username %s, role %s", claims.Username, claims.Role)
	}
}

func TestRefreshTokenRotation(t *testing.T) {
	svc, s := setupTestService()
	user, _ := s.GetUserByUsername("admin")

	initialTokens, err := svc.GenerateTokenPair(user, "device-1")
	if err != nil {
		t.Fatalf("Initial GenerateTokenPair failed: %v", err)
	}

	// Refresh 1: Should succeed
	newTokens, err := svc.RefreshToken(initialTokens.RefreshToken)
	if err != nil {
		t.Fatalf("First refresh failed: %v", err)
	}

	if newTokens.RefreshToken == initialTokens.RefreshToken {
		t.Fatal("Refresh token rotation expected new refresh token")
	}

	// Refresh with OLD token: Should fail because it was revoked
	_, err = svc.RefreshToken(initialTokens.RefreshToken)
	if err == nil {
		t.Fatal("Re-using old refresh token must be rejected by rotation policy")
	}
}

func TestBiometricChallengeResponse(t *testing.T) {
	svc, _ := setupTestService()

	// 1. Issue challenge
	challenge, err := svc.CreateChallenge("device-abc")
	if err != nil {
		t.Fatalf("CreateChallenge failed: %v", err)
	}

	if challenge.Nonce == "" {
		t.Fatal("Nonce should not be empty")
	}

	// 2. Verify with valid signature
	tokens, user, err := svc.VerifyBiometricChallenge(&models.BiometricVerifyRequest{
		DeviceID:  "device-abc",
		Nonce:     challenge.Nonce,
		Signature: "valid_ecdsa_sha256_mock_sig",
	})
	if err != nil {
		t.Fatalf("Biometric verification failed: %v", err)
	}

	if user == nil || tokens.AccessToken == "" {
		t.Fatal("Expected authenticated user and tokens")
	}

	// 3. Re-using same nonce must fail (one-time nonces)
	_, _, err = svc.VerifyBiometricChallenge(&models.BiometricVerifyRequest{
		DeviceID:  "device-abc",
		Nonce:     challenge.Nonce,
		Signature: "valid_ecdsa_sha256_mock_sig",
	})
	if err == nil {
		t.Fatal("Replay attack with already consumed nonce must fail")
	}
}
