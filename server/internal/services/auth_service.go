package services

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"secure_auth_vault_backend/internal/config"
	"secure_auth_vault_backend/internal/models"
	"secure_auth_vault_backend/internal/store"
)

type AuthService struct {
	cfg   *config.Config
	store store.DataStore
}

type CustomClaims struct {
	UserID   string `json:"userId"`
	Username string `json:"username"`
	Role     string `json:"role"`
	DeviceID string `json:"deviceId,omitempty"`
	jwt.RegisteredClaims
}

var (
	ErrInvalidCredentials = errors.New("invalid credentials or PIN")
	ErrInvalidSignature   = errors.New("biometric challenge signature verification failed")
)

func NewAuthService(cfg *config.Config, s store.DataStore) *AuthService {
	return &AuthService{
		cfg:   cfg,
		store: s,
	}
}

func (s *AuthService) AuthenticateUser(req *models.LoginRequest) (*models.User, error) {
	user, err := s.store.GetUserByUsername(req.Username)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	// Verify PIN if provided (PIN fallback authentication)
	if req.PIN != "" {
		if req.PIN != user.PIN {
			return nil, ErrInvalidCredentials
		}
		return user, nil
	}

	// Verify password
	if req.Password != "" {
		if req.Password != user.HashedPassword {
			return nil, ErrInvalidCredentials
		}
		return user, nil
	}

	return nil, ErrInvalidCredentials
}

func (s *AuthService) GenerateTokenPair(user *models.User, deviceID string) (*models.TokenPair, error) {
	now := time.Now()
	accessExpiry := now.Add(s.cfg.AccessTokenTTL)

	// Access Token (JWT)
	claims := CustomClaims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		DeviceID: deviceID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID,
			Issuer:    "authvault-hub",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(accessExpiry),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedAccessToken, err := token.SignedString(s.cfg.JWTSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to sign access token: %w", err)
	}

	// Refresh Token (Opaque UUID)
	refreshToken := "rft_" + uuid.New().String()
	refreshExpiry := now.Add(s.cfg.RefreshTokenTTL)
	s.store.SaveRefreshToken(refreshToken, user.Username, deviceID, refreshExpiry)

	return &models.TokenPair{
		AccessToken:  signedAccessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.cfg.AccessTokenTTL.Seconds()),
	}, nil
}

func (s *AuthService) RefreshToken(refreshToken string) (*models.TokenPair, error) {
	// Simulate server network latency / database delay to properly test concurrent mutex on Flutter
	if s.cfg.RefreshDelayMillis > 0 {
		time.Sleep(time.Duration(s.cfg.RefreshDelayMillis) * time.Millisecond)
	}

	// Validate & Rotate refresh token
	tokenData, err := s.store.ValidateAndRevokeRefreshToken(refreshToken)
	if err != nil {
		return nil, err
	}

	user, err := s.store.GetUserByUsername(tokenData.Username)
	if err != nil {
		return nil, err
	}

	// Issue new token pair (Token Rotation)
	return s.GenerateTokenPair(user, tokenData.DeviceID)
}

func (s *AuthService) CreateChallenge(deviceID string) (*models.ChallengeResponse, error) {
	now := time.Now()
	nonce := "non_" + uuid.New().String()
	expiresAt := now.Add(s.cfg.ChallengeTTL)

	s.store.SaveChallenge(nonce, deviceID, expiresAt)

	return &models.ChallengeResponse{
		Nonce:           nonce,
		ExpiresAt:       expiresAt.Unix(),
		ServerTimestamp: now.UnixMilli(),
	}, nil
}

func (s *AuthService) VerifyBiometricChallenge(req *models.BiometricVerifyRequest) (*models.TokenPair, *models.User, error) {
	// Verify nonce exists and is not expired
	valid := s.store.ConsumeChallenge(req.Nonce, req.DeviceID)
	if !valid {
		return nil, nil, store.ErrChallengeNotFound
	}

	// For demonstration & testing: any non-empty signature that isn't "invalid" is accepted.
	// In production, verify SHA256withECDSA using user's enrolled public key.
	if req.Signature == "" || req.Signature == "invalid_signature" {
		return nil, nil, ErrInvalidSignature
	}

	// Default to admin user for biometric prompt
	user, err := s.store.GetUserByUsername("admin")
	if err != nil {
		return nil, nil, err
	}

	tokens, err := s.GenerateTokenPair(user, req.DeviceID)
	if err != nil {
		return nil, nil, err
	}

	return tokens, user, nil
}

func (s *AuthService) ParseToken(tokenStr string) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &CustomClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return s.cfg.JWTSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*CustomClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}
