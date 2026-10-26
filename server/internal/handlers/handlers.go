package handlers

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"secure_auth_vault_backend/internal/models"
	"secure_auth_vault_backend/internal/services"
	"secure_auth_vault_backend/internal/store"
)

type Handlers struct {
	authService *services.AuthService
	store       store.DataStore
}

func NewHandlers(authService *services.AuthService, s store.DataStore) *Handlers {
	return &Handlers{
		authService: authService,
		store:       s,
	}
}

// POST /api/v1/auth/login
func (h *Handlers) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Code:    "BAD_REQUEST",
			Message: "Invalid request payload: " + err.Error(),
		})
		return
	}

	user, err := h.authService.AuthenticateUser(&req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Code:    "AUTH_FAILED",
			Message: err.Error(),
		})
		return
	}

	tokens, err := h.authService.GenerateTokenPair(user, req.DeviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Code:    "INTERNAL_ERROR",
			Message: "Failed to generate session tokens",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "LOGIN_SUCCESS",
		Message: "Authentication successful",
		Data: gin.H{
			"user": models.UserProfile{
				ID:        user.ID,
				Username:  user.Username,
				Role:      user.Role,
				DeviceID:  req.DeviceID,
				LastLogin: time.Now(),
			},
			"tokens": tokens,
		},
	})
}

// POST /api/v1/auth/refresh
func (h *Handlers) RefreshToken(c *gin.Context) {
	var req models.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Code:    "BAD_REQUEST",
			Message: "Missing refresh token",
		})
		return
	}

	log.Printf("[REFRESH_CALL] Received refresh token request -> %s", req.RefreshToken)

	tokens, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		log.Printf("[REFRESH_ERROR] Token refresh rejected: %v", err)
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Code:    "REFRESH_FAILED",
			Message: "Refresh token is invalid or expired: " + err.Error(),
		})
		return
	}

	log.Printf("[REFRESH_SUCCESS] Successfully rotated tokens. New refresh token: %s", tokens.RefreshToken)

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "REFRESH_SUCCESS",
		Message: "Token rotated successfully",
		Data:    tokens,
	})
}

// GET /api/v1/auth/biometric/challenge
func (h *Handlers) GetBiometricChallenge(c *gin.Context) {
	deviceID := c.Query("deviceId")
	if deviceID == "" {
		deviceID = c.GetHeader("Device-ID")
	}

	challenge, err := h.authService.CreateChallenge(deviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Code:    "CHALLENGE_FAILED",
			Message: "Failed to generate challenge",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "CHALLENGE_ISSUED",
		Message: "Challenge nonce issued successfully",
		Data:    challenge,
	})
}

// POST /api/v1/auth/biometric/verify
func (h *Handlers) VerifyBiometric(c *gin.Context) {
	var req models.BiometricVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.APIResponse{
			Success: false,
			Code:    "BAD_REQUEST",
			Message: err.Error(),
		})
		return
	}

	tokens, user, err := h.authService.VerifyBiometricChallenge(&req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Code:    "BIOMETRIC_VERIFY_FAILED",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "BIOMETRIC_AUTH_SUCCESS",
		Message: "Biometric challenge signature verified",
		Data: gin.H{
			"user": models.UserProfile{
				ID:        user.ID,
				Username:  user.Username,
				Role:      user.Role,
				DeviceID:  req.DeviceID,
				LastLogin: time.Now(),
			},
			"tokens": tokens,
		},
	})
}

// POST /api/v1/auth/logout
func (h *Handlers) Logout(c *gin.Context) {
	var req models.RefreshRequest
	_ = c.ShouldBindJSON(&req)
	if req.RefreshToken != "" {
		h.store.RevokeRefreshToken(req.RefreshToken)
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "LOGOUT_SUCCESS",
		Message: "Session terminated successfully",
	})
}

// GET /api/v1/user/profile (Protected)
func (h *Handlers) GetProfile(c *gin.Context) {
	claimsVal, exists := c.Get("claims")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.APIResponse{
			Success: false,
			Code:    "UNAUTHORIZED",
			Message: "No claims found",
		})
		return
	}

	claims := claimsVal.(*services.CustomClaims)
	user, err := h.store.GetUserByUsername(claims.Username)
	if err != nil {
		c.JSON(http.StatusNotFound, models.APIResponse{
			Success: false,
			Code:    "USER_NOT_FOUND",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "SUCCESS",
		Data: models.UserProfile{
			ID:        user.ID,
			Username:  user.Username,
			Role:      user.Role,
			DeviceID:  claims.DeviceID,
			LastLogin: time.Now(),
		},
	})
}

// GET /api/v1/vault/items (Protected - used for 401 concurrent race test)
func (h *Handlers) GetVaultItems(c *gin.Context) {
	items := h.store.GetVaultItems()
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Code:    "SUCCESS",
		Data:    items,
	})
}

// GET /api/v1/health
func (h *Handlers) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ONLINE",
		"service": "AuthVault Enterprise Gateway",
		"version": "1.0.0",
		"time":    time.Now().Format(time.RFC3339),
	})
}
