package store

import (
	"errors"
	"sync"
	"time"

	"secure_auth_vault_backend/internal/models"
)

type RefreshTokenData struct {
	Token     string
	Username  string
	DeviceID  string
	ExpiresAt time.Time
	Revoked   bool
}

type ChallengeData struct {
	Nonce     string
	DeviceID  string
	ExpiresAt time.Time
}

type DataStore interface {
	GetUserByUsername(username string) (*models.User, error)
	SaveRefreshToken(token, username, deviceID string, expiresAt time.Time)
	ValidateAndRevokeRefreshToken(token string) (*RefreshTokenData, error)
	RevokeRefreshToken(token string)
	SaveChallenge(nonce, deviceID string, expiresAt time.Time)
	ConsumeChallenge(nonce, deviceID string) bool
	GetVaultItems() []models.VaultItem
	Close() error
}

type MemoryStore struct {
	mu            sync.RWMutex
	users         map[string]*models.User
	refreshTokens map[string]*RefreshTokenData
	challenges    map[string]*ChallengeData
	vaultItems    []models.VaultItem
}

var (
	ErrUserNotFound      = errors.New("user not found")
	ErrInvalidToken      = errors.New("invalid or revoked refresh token")
	ErrChallengeNotFound = errors.New("challenge not found or expired")
)

func NewMemoryStore() *MemoryStore {
	s := &MemoryStore{
		users:         make(map[string]*models.User),
		refreshTokens: make(map[string]*RefreshTokenData),
		challenges:    make(map[string]*ChallengeData),
	}
	s.seedDefaultData()
	return s
}

func (s *MemoryStore) seedDefaultData() {
	now := time.Now()
	s.users["admin"] = &models.User{
		ID:             "usr_admin_001",
		Username:       "admin",
		HashedPassword: "admin123",
		PIN:            "123456",
		Role:           "SECURITY_OFFICER",
		CreatedAt:      now.Add(-30 * 24 * time.Hour),
	}
	s.users["operator"] = &models.User{
		ID:             "usr_op_002",
		Username:       "operator",
		HashedPassword: "operator123",
		PIN:            "654321",
		Role:           "FINTECH_OPERATOR",
		CreatedAt:      now.Add(-10 * 24 * time.Hour),
	}
	s.vaultItems = []models.VaultItem{
		{
			ID:            "vlt_01",
			Title:         "SWIFT MT103 Interbank Gateway",
			Category:      "FINANCIAL_GATEWAY",
			SecretSnippet: "sec_live_9988_a7b4_swift_sign_key",
			SecurityLevel: "L3_HARDWARE_BACKED",
			LastAccessed:  now.Add(-2 * time.Minute),
		},
		{
			ID:            "vlt_02",
			Title:         "HSM Root Master Key Fragment #1",
			Category:      "CRYPTO_VAULT",
			SecretSnippet: "hsm_sharding_kdf2_fragment_3901",
			SecurityLevel: "L3_HARDWARE_BACKED",
			LastAccessed:  now.Add(-15 * time.Minute),
		},
		{
			ID:            "vlt_03",
			Title:         "Core Banking REST API Gateway v3",
			Category:      "CORE_BANKING",
			SecretSnippet: "bearer_live_prod_cba_2026_cluster",
			SecurityLevel: "L2_BIOMETRIC_GUARDED",
			LastAccessed:  now.Add(-1 * time.Hour),
		},
		{
			ID:            "vlt_04",
			Title:         "PCI-DSS Cardholder Data Vault",
			Category:      "PAYMENT_VAULT",
			SecretSnippet: "aes_gcm_256_enc_pci_session_key",
			SecurityLevel: "L2_BIOMETRIC_GUARDED",
			LastAccessed:  now.Add(-5 * time.Hour),
		},
	}
}

func (s *MemoryStore) GetUserByUsername(username string) (*models.User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	user, exists := s.users[username]
	if !exists {
		return nil, ErrUserNotFound
	}
	return user, nil
}

func (s *MemoryStore) SaveRefreshToken(token, username, deviceID string, expiresAt time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.refreshTokens[token] = &RefreshTokenData{
		Token:     token,
		Username:  username,
		DeviceID:  deviceID,
		ExpiresAt: expiresAt,
		Revoked:   false,
	}
}

func (s *MemoryStore) ValidateAndRevokeRefreshToken(token string) (*RefreshTokenData, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	data, exists := s.refreshTokens[token]
	if !exists || data.Revoked || time.Now().After(data.ExpiresAt) {
		return nil, ErrInvalidToken
	}
	data.Revoked = true
	return data, nil
}

func (s *MemoryStore) RevokeRefreshToken(token string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if data, exists := s.refreshTokens[token]; exists {
		data.Revoked = true
	}
}

func (s *MemoryStore) SaveChallenge(nonce, deviceID string, expiresAt time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.challenges[nonce] = &ChallengeData{
		Nonce:     nonce,
		DeviceID:  deviceID,
		ExpiresAt: expiresAt,
	}
}

func (s *MemoryStore) ConsumeChallenge(nonce, deviceID string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	data, exists := s.challenges[nonce]
	if !exists {
		return false
	}
	delete(s.challenges, nonce)
	if time.Now().After(data.ExpiresAt) {
		return false
	}
	if data.DeviceID != "" && deviceID != "" && data.DeviceID != deviceID {
		return false
	}
	return true
}

func (s *MemoryStore) GetVaultItems() []models.VaultItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	items := make([]models.VaultItem, len(s.vaultItems))
	copy(items, s.vaultItems)
	return items
}

func (s *MemoryStore) Close() error {
	return nil
}
