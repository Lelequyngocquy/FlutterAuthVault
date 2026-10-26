package store

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"

	"secure_auth_vault_backend/internal/models"
)

type PostgresStore struct {
	db *sql.DB
}

func NewPostgresStore(host, port, user, password, dbname, sslmode string) (*PostgresStore, error) {
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, dbname, sslmode)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}
	return &PostgresStore{db: db}, nil
}

func (p *PostgresStore) GetUserByUsername(username string) (*models.User, error) {
	var u models.User
	var bioKey sql.NullString
	query := `SELECT id, username, password_hash, pin, biometric_public_key, role, created_at FROM users WHERE username = $1`
	err := p.db.QueryRow(query, username).Scan(
		&u.ID,
		&u.Username,
		&u.HashedPassword,
		&u.PIN,
		&bioKey,
		&u.Role,
		&u.CreatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	if bioKey.Valid {
		u.BiometricPublicKey = bioKey.String
	}
	return &u, nil
}

func (p *PostgresStore) SaveRefreshToken(token, username, deviceID string, expiresAt time.Time) {
	query := `INSERT INTO refresh_tokens (token, username, device_id, expires_at, revoked) 
	          VALUES ($1, $2, $3, $4, false)
	          ON CONFLICT (token) DO UPDATE SET revoked = false, expires_at = $4`
	_, _ = p.db.Exec(query, token, username, deviceID, expiresAt)
}

func (p *PostgresStore) ValidateAndRevokeRefreshToken(token string) (*RefreshTokenData, error) {
	tx, err := p.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	var d RefreshTokenData
	var devId sql.NullString
	query := `SELECT token, username, device_id, expires_at, revoked FROM refresh_tokens WHERE token = $1 FOR UPDATE`
	err = tx.QueryRow(query, token).Scan(&d.Token, &d.Username, &devId, &d.ExpiresAt, &d.Revoked)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrInvalidToken
		}
		return nil, err
	}
	if devId.Valid {
		d.DeviceID = devId.String
	}
	if d.Revoked || time.Now().After(d.ExpiresAt) {
		return nil, ErrInvalidToken
	}
	updateQuery := `UPDATE refresh_tokens SET revoked = true WHERE token = $1`
	if _, err := tx.Exec(updateQuery, token); err != nil {
		return nil, err
	}
	if err := tx.Commit(); err != nil {
		return nil, err
	}
	d.Revoked = true
	return &d, nil
}

func (p *PostgresStore) RevokeRefreshToken(token string) {
	query := `UPDATE refresh_tokens SET revoked = true WHERE token = $1`
	_, _ = p.db.Exec(query, token)
}

func (p *PostgresStore) SaveChallenge(nonce, deviceID string, expiresAt time.Time) {
	query := `INSERT INTO challenges (nonce, device_id, expires_at, consumed) 
	          VALUES ($1, $2, $3, false)
	          ON CONFLICT (nonce) DO UPDATE SET consumed = false, expires_at = $3`
	_, _ = p.db.Exec(query, nonce, deviceID, expiresAt)
}

func (p *PostgresStore) ConsumeChallenge(nonce, deviceID string) bool {
	tx, err := p.db.Begin()
	if err != nil {
		return false
	}
	defer tx.Rollback()
	var d ChallengeData
	var consumed bool
	var devId sql.NullString
	query := `SELECT nonce, device_id, expires_at, consumed FROM challenges WHERE nonce = $1 FOR UPDATE`
	err = tx.QueryRow(query, nonce).Scan(&d.Nonce, &devId, &d.ExpiresAt, &consumed)
	if err != nil {
		return false
	}
	if devId.Valid {
		d.DeviceID = devId.String
	}
	if consumed || time.Now().After(d.ExpiresAt) {
		return false
	}
	if d.DeviceID != "" && deviceID != "" && d.DeviceID != deviceID {
		return false
	}
	updateQuery := `UPDATE challenges SET consumed = true WHERE nonce = $1`
	if _, err := tx.Exec(updateQuery, nonce); err != nil {
		return false
	}
	if err := tx.Commit(); err != nil {
		return false
	}
	return true
}

func (p *PostgresStore) GetVaultItems() []models.VaultItem {
	query := `SELECT id, title, category, secret_snippet, security_level, last_accessed FROM vault_items`
	rows, err := p.db.Query(query)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var items []models.VaultItem
	for rows.Next() {
		var item models.VaultItem
		if err := rows.Scan(&item.ID, &item.Title, &item.Category, &item.SecretSnippet, &item.SecurityLevel, &item.LastAccessed); err == nil {
			items = append(items, item)
		}
	}
	return items
}

func (p *PostgresStore) Close() error {
	return p.db.Close()
}
