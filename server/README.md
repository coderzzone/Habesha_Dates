# Chapa Payment Backend

This server securely integrates Chapa payments for the Flutter app.

## Endpoints

- `POST /payments/chapa/initialize`
- `POST /payments/chapa/verify`
- `GET /health`

## Setup

1. `cd server`
2. `npm install`
3. Copy `.env.example` to `.env`
4. Fill your values in `.env`:
   - `CHAPA_SECRET_KEY`
   - `CHAPA_PUBLIC_KEY` (optional for reference)
   - `CHAPA_ENCRYPTION_KEY` (optional for advanced flows)
5. Ensure Firebase Admin credentials are available to this process:
   - Local: set `GOOGLE_APPLICATION_CREDENTIALS` to your service-account JSON path
6. Start server:
   - `npm start`

## App configuration

Flutter app reads backend URL from:

- `PAYMENT_BACKEND_BASE_URL` (dart-define), default is `http://10.0.2.2:8787`
- `PAYMENT_RETURN_URL` (dart-define), default is `habeshadates://payment/callback`

Example:

```bash
flutter run --dart-define=PAYMENT_BACKEND_BASE_URL=http://10.0.2.2:8787 --dart-define=PAYMENT_RETURN_URL=habeshadates://payment/callback
```

## Security

- Never put `CHAPA_SECRET_KEY` in Flutter/mobile source code.
- Keep all payment verification and entitlement application on this backend.

