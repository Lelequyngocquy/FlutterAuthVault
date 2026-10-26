package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"secure_auth_vault_backend/internal/config"
	"secure_auth_vault_backend/internal/middleware"
	"secure_auth_vault_backend/internal/models"
	"secure_auth_vault_backend/internal/services"
	"secure_auth_vault_backend/internal/store"
)

func setupTestRouter() (*gin.Engine, *services.AuthService, *store.MemoryStore) {
	gin.SetMode(gin.TestMode)
	cfg := &config.Config{
		Port:               "8080",
		JWTSecret:          []byte("integration_test_secret_key_1234"),
		AccessTokenTTL:     1 * time.Second, // 1s access token for rapid expiry test
		RefreshTokenTTL:    1 * time.Hour,
		ChallengeTTL:       60 * time.Second,
		RefreshDelayMillis: 100, // 100ms artificial delay
	}

	memStore := store.NewMemoryStore()
	authService := services.NewAuthService(cfg, memStore)
	h := NewHandlers(authService, memStore)

	r := gin.New()
	r.Use(gin.Recovery())

	v1 := r.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/login", h.Login)
			auth.POST("/refresh", h.RefreshToken)
		}

		protected := v1.Group("")
		protected.Use(middleware.JWTAuth(authService))
		{
			protected.GET("/vault/items", h.GetVaultItems)
		}
	}

	return r, authService, memStore
}

func TestConcurrentVaultRequestsAfterTokenExpiry(t *testing.T) {
	router, authService, memStore := setupTestRouter()

	// 1. Login to get initial tokens
	adminUser, _ := memStore.GetUserByUsername("admin")
	initialTokens, err := authService.GenerateTokenPair(adminUser, "test-device-concurrent")
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}

	// 2. Call protected endpoint with valid token -> Must return 200 OK
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/vault/items", nil)
	req.Header.Set("Authorization", "Bearer "+initialTokens.AccessToken)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d", w.Code)
	}

	// 3. Wait 1.1s for token to expire
	time.Sleep(1100 * time.Millisecond)

	// 4. Send 5 concurrent requests with the expired token -> All must receive 401
	var wg sync.WaitGroup
	var mu sync.Mutex
	statusCodes := make([]int, 0, 5)

	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			rec := httptest.NewRecorder()
			r, _ := http.NewRequest("GET", "/api/v1/vault/items", nil)
			r.Header.Set("Authorization", "Bearer "+initialTokens.AccessToken)
			router.ServeHTTP(rec, r)

			mu.Lock()
			statusCodes = append(statusCodes, rec.Code)
			mu.Unlock()
		}()
	}
	wg.Wait()

	// All 5 should be 401 Unauthorized
	for _, code := range statusCodes {
		if code != http.StatusUnauthorized {
			t.Errorf("Expected 401 for expired token, got %d", code)
		}
	}

	// 5. Refresh token once
	refreshBody, _ := json.Marshal(models.RefreshRequest{RefreshToken: initialTokens.RefreshToken})
	wRefresh := httptest.NewRecorder()
	reqRefresh, _ := http.NewRequest("POST", "/api/v1/auth/refresh", bytes.NewBuffer(refreshBody))
	reqRefresh.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(wRefresh, reqRefresh)

	if wRefresh.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK from refresh, got %d: %s", wRefresh.Code, wRefresh.Body.String())
	}

	var refreshResp models.APIResponse
	json.Unmarshal(wRefresh.Body.Bytes(), &refreshResp)

	// Convert Data map to TokenPair
	dataBytes, _ := json.Marshal(refreshResp.Data)
	var newTokens models.TokenPair
	json.Unmarshal(dataBytes, &newTokens)

	if newTokens.AccessToken == "" {
		t.Fatal("Expected new access token")
	}

	// 6. Replay 5 requests with the new token -> All 5 must succeed with 200 OK!
	statusCodes = statusCodes[:0]
	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			rec := httptest.NewRecorder()
			r, _ := http.NewRequest("GET", "/api/v1/vault/items", nil)
			r.Header.Set("Authorization", "Bearer "+newTokens.AccessToken)
			router.ServeHTTP(rec, r)

			mu.Lock()
			statusCodes = append(statusCodes, rec.Code)
			mu.Unlock()
		}()
	}
	wg.Wait()

	for _, code := range statusCodes {
		if code != http.StatusOK {
			t.Errorf("Expected 200 OK after token refresh, got %d", code)
		}
	}
}
