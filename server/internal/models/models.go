package models

import "time"

// Base API Response matching Flutter's BaseResponse
type APIResponse struct {
	Success bool   `json:"isSuccess"`
	Code    string `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
}

type User struct {
	ID                 string    `json:"id"`
	Username           string    `json:"username"`
	HashedPassword     string    `json:"-"`
	PIN                string    `json:"-"` // Hashed or plain 6-digit PIN for demo
	BiometricPublicKey string    `json:"biometricPublicKey,omitempty"`
	Role               string    `json:"role"`
	CreatedAt          time.Time `json:"createdAt"`
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password,omitempty"`
	PIN      string `json:"pin,omitempty"`
	DeviceID string `json:"deviceId,omitempty"`
}

type TokenPair struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	TokenType    string `json:"tokenType"`
	ExpiresIn    int64  `json:"expiresIn"` // seconds
}

type RefreshRequest struct {
	RefreshToken string `json:"refreshToken" binding:"required"`
}

type ChallengeResponse struct {
	Nonce           string `json:"nonce"`
	ExpiresAt       int64  `json:"expiresAt"`
	ServerTimestamp int64  `json:"serverTimestamp"`
}

type BiometricVerifyRequest struct {
	DeviceID  string `json:"deviceId" binding:"required"`
	Nonce     string `json:"nonce" binding:"required"`
	Signature string `json:"signature" binding:"required"`
}

type UserProfile struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Role      string    `json:"role"`
	DeviceID  string    `json:"deviceId"`
	LastLogin time.Time `json:"lastLogin"`
}

type VaultItem struct {
	ID            string    `json:"id"`
	Title         string    `json:"title"`
	Category      string    `json:"category"`
	SecretSnippet string    `json:"secretSnippet"`
	SecurityLevel string    `json:"securityLevel"` // L1_STANDARD, L2_BIOMETRIC, L3_HARDWARE
	LastAccessed  time.Time `json:"lastAccessed"`
}
