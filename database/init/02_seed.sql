INSERT INTO users (id, username, password_hash, pin, role, created_at)
VALUES 
    ('usr_admin_001', 'admin', 'admin123', '123456', 'SECURITY_OFFICER', NOW() - INTERVAL '30 days'),
    ('usr_op_002', 'operator', 'operator123', '654321', 'FINTECH_OPERATOR', NOW() - INTERVAL '10 days')
ON CONFLICT (username) DO NOTHING;

INSERT INTO vault_items (id, title, category, secret_snippet, security_level, last_accessed)
VALUES
    ('vlt_01', 'SWIFT MT103 Interbank Gateway', 'FINANCIAL_GATEWAY', 'sec_live_9988_a7b4_swift_sign_key', 'L3_HARDWARE_BACKED', NOW() - INTERVAL '2 minutes'),
    ('vlt_02', 'HSM Root Master Key Fragment #1', 'CRYPTO_VAULT', 'hsm_sharding_kdf2_fragment_3901', 'L3_HARDWARE_BACKED', NOW() - INTERVAL '15 minutes'),
    ('vlt_03', 'Core Banking REST API Gateway v3', 'CORE_BANKING', 'bearer_live_prod_cba_2026_cluster', 'L2_BIOMETRIC_GUARDED', NOW() - INTERVAL '1 hour'),
    ('vlt_04', 'PCI-DSS Cardholder Data Vault', 'PAYMENT_VAULT', 'aes_gcm_256_enc_pci_session_key', 'L2_BIOMETRIC_GUARDED', NOW() - INTERVAL '5 hours')
ON CONFLICT (id) DO NOTHING;
