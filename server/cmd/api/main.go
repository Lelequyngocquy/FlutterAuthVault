package main

import (
	"fmt"
	"log"

	"github.com/gin-gonic/gin"

	"secure_auth_vault_backend/internal/config"
	"secure_auth_vault_backend/internal/handlers"
	"secure_auth_vault_backend/internal/middleware"
	"secure_auth_vault_backend/internal/services"
	"secure_auth_vault_backend/internal/store"
)

func main() {
	cfg := config.LoadConfig()
	var dataStore store.DataStore
	if cfg.DBHost != "" {
		pgStore, err := store.NewPostgresStore(cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode)
		if err != nil {
			log.Printf("[AUTHVAULT] Postgres connection failed: %v. Falling back to memory store.", err)
			dataStore = store.NewMemoryStore()
		} else {
			log.Printf("[AUTHVAULT] Connected to PostgreSQL at %s:%s (Database: %s)", cfg.DBHost, cfg.DBPort, cfg.DBName)
			dataStore = pgStore
		}
	} else {
		log.Printf("[AUTHVAULT] No DB_HOST specified. Initializing in-memory data store.")
		dataStore = store.NewMemoryStore()
	}
	defer dataStore.Close()
	authService := services.NewAuthService(cfg, dataStore)
	h := handlers.NewHandlers(authService, dataStore)
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.CORSMiddleware())
	router.Use(middleware.RequestLogger())
	router.GET("/health", h.Health)
	router.GET("/api/v1/health", h.Health)
	v1 := router.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/login", h.Login)
			auth.POST("/refresh", h.RefreshToken)
			auth.POST("/logout", h.Logout)
			auth.GET("/biometric/challenge", h.GetBiometricChallenge)
			auth.POST("/biometric/verify", h.VerifyBiometric)
		}
		protected := v1.Group("")
		protected.Use(middleware.JWTAuth(authService))
		{
			protected.GET("/user/profile", h.GetProfile)
			protected.GET("/vault/items", h.GetVaultItems)
		}
	}
	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("=====================================================")
	log.Printf("[AUTHVAULT] Backend API running on http://localhost%s", addr)
	log.Printf("   - Access Token TTL: %v", cfg.AccessTokenTTL)
	log.Printf("   - Token Refresh Artificial Delay: %dms", cfg.RefreshDelayMillis)
	log.Printf("   - Challenge TTL: %v", cfg.ChallengeTTL)
	log.Printf("=====================================================")
	if err := router.Run(addr); err != nil {
		log.Fatalf("Server startup failed: %v", err)
	}
}
