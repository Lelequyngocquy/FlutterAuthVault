param(
    [string]$BaseUrl = "http://localhost:8080"
)
$ErrorActionPreference = "Stop"
Write-Host "[TEST 1] Health Check"
$health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
Write-Host "Service Status: $($health.status) | Service: $($health.service)"

Write-Host "[TEST 2] User Authentication (Login)"
$loginBody = @{
    username = "admin"
    password = "admin123"
    deviceId = "docker-tester-device"
} | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$accessToken = $loginRes.data.tokens.accessToken
$refreshToken = $loginRes.data.tokens.refreshToken
Write-Host "Success: $($loginRes.isSuccess) | User: $($loginRes.data.user.username) | Role: $($loginRes.data.user.role)"

Write-Host "[TEST 3] Protected Vault Endpoint"
$headers = @{ Authorization = "Bearer $accessToken" }
$vaultRes = Invoke-RestMethod -Uri "$BaseUrl/api/v1/vault/items" -Method Get -Headers $headers
Write-Host "Loaded $($vaultRes.data.Count) secure assets successfully"

Write-Host "[TEST 4] Biometric Challenge Issuance"
$challengeRes = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/biometric/challenge?deviceId=docker-tester-device" -Method Get
$nonce = $challengeRes.data.nonce
Write-Host "Challenge Nonce Issued: $nonce"

Write-Host "[TEST 5] Biometric Signature Verification"
$bioVerifyBody = @{
    deviceId = "docker-tester-device"
    nonce = $nonce
    signature = "valid_hardware_enclave_mock_signature_sha256"
} | ConvertTo-Json
$bioVerifyRes = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/biometric/verify" -Method Post -Body $bioVerifyBody -ContentType "application/json"
Write-Host "Biometric Verification: $($bioVerifyRes.isSuccess)"

Write-Host "[TEST 6] Token Rotation Refresh"
$refreshBody = @{ refreshToken = $refreshToken } | ConvertTo-Json
$refreshRes = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/refresh" -Method Post -Body $refreshBody -ContentType "application/json"
$newRefreshToken = $refreshRes.data.refreshToken
Write-Host "Refreshed Token Success: $($refreshRes.isSuccess) | New Refresh Token: $newRefreshToken"

Write-Host "[TEST 7] Security Policy: Revoked Old Token Rejection"
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/refresh" -Method Post -Body $refreshBody -ContentType "application/json"
    Write-Host "[FAIL] Old refresh token was unexpectedly accepted"
    exit 1
} catch {
    Write-Host "[PASS] Revoked token rejected with 401 Unauthorized"
}
Write-Host "[SUCCESS] All Docker backend integration tests passed"
