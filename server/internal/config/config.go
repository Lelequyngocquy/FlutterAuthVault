package config

import (
	"os"
	"time"
)

type Config struct {
	Port               string
	JWTSecret          []byte
	AccessTokenTTL     time.Duration
	RefreshTokenTTL    time.Duration
	ChallengeTTL       time.Duration
	RefreshDelayMillis int
	DBHost             string
	DBPort             string
	DBUser             string
	DBPassword         string
	DBName             string
	DBSSLMode          string
}

func LoadConfig() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "enterprise_super_secure_vault_jwt_secret_key_2026!"
	}
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "vault_user"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "vault_secure_password_2026"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "authvault"
	}
	dbSSLMode := os.Getenv("DB_SSLMODE")
	if dbSSLMode == "" {
		dbSSLMode = "disable"
	}
	return &Config{
		Port:               port,
		JWTSecret:          []byte(secret),
		AccessTokenTTL:     30 * time.Second,
		RefreshTokenTTL:    7 * 24 * time.Hour,
		ChallengeTTL:       60 * time.Second,
		RefreshDelayMillis: 300,
		DBHost:             dbHost,
		DBPort:             dbPort,
		DBUser:             dbUser,
		DBPassword:         dbPassword,
		DBName:             dbName,
		DBSSLMode:          dbSSLMode,
	}
}
