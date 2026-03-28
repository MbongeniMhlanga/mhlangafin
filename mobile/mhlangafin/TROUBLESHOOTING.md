# Mobile App Login Troubleshooting Guide

## Issue Fixed
The mobile app login was failing due to network connectivity issues between the mobile app and the backend API server.

## Root Causes Identified and Fixed

### 1. iOS Network Security (ATS)
**Problem**: iOS blocks HTTP connections by default for security reasons.
**Solution**: Added `NSAppTransportSecurity` exception for localhost in `Info.plist`.

### 2. Android Network Permissions
**Problem**: Android app lacked internet permissions.
**Solution**: Added `INTERNET` and `ACCESS_NETWORK_STATE` permissions in `AndroidManifest.xml`.

### 3. Backend CORS Configuration
**Problem**: Backend only allowed connections from Angular frontend (localhost:4200).
**Solution**: Updated CORS policy to allow connections from any origin.

### 4. Mobile App API URL
**Problem**: Using `localhost` doesn't work in Android emulator.
**Solution**: Changed to `10.0.2.2` which is the Android emulator's alias for localhost.

### 5. Account Fetching Endpoint
**Problem**: Mobile app was calling `/api/accounts` instead of `/api/accounts/my`.
**Solution**: Updated API service to use the correct endpoint for fetching user accounts.

## How to Test the Fix

### 1. Start the Backend Server
```bash
cd Backend
dotnet run
```
The server should start on `http://localhost:5075`

### 2. Test Backend Connection
```bash
# Run the test script
./test_backend_connection.sh

# Or manually test with curl
curl -X POST http://localhost:5075/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 3. Run the Mobile App
```bash
cd mobile/mhlangafin
flutter run
```

### 4. Test Login Flow
1. Open the app
2. Try to login with valid credentials
3. The app should now successfully connect to the backend

## For iOS Development
If testing on iOS simulator, the app should work with the updated `Info.plist` configuration.

## For Android Development
If testing on Android emulator, the app uses `10.0.2.2` to connect to localhost.

## For Physical Device Testing
If testing on a physical device, you'll need to:
1. Use your computer's IP address instead of localhost
2. Ensure both device and computer are on the same network
3. Update the `baseUrl` in `api_service.dart` to use your computer's IP

Example:
```dart
static const String baseUrl = 'http://192.168.1.100:5075/api';
```

## Common Issues

### Connection Timeout
- Ensure backend server is running
- Check firewall settings
- Verify network connectivity

### Authentication Errors
- Check that user exists in database
- Verify email and password are correct
- Check JWT configuration in backend

### CORS Errors
- Ensure backend CORS policy is set to allow all origins
- Check that backend is running on correct port

## Backend Database
The backend automatically creates a database and sample data when started. The first user created gets a Main Account with R1,000,000 balance.