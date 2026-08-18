# Staging Smoke & Reliability Verification Checklist

This checklist documents manual and scripted verification steps for staging deployments of Alpha Cues MVP.

---

## 1. Authentication Flow
- [ ] **Send OTP**: Enter a valid email address on `/login`. Verify 201 Created response and email arrival (or console/Mailpit log).
- [ ] **Rate Limiting**: Trigger 6 OTP send requests in under 1 minute from the same IP. Confirm request 6 receives HTTP `429 RATE_LIMITED` response and is logged under `RATE_LIMITED`.
- [ ] **OTP Verification**: Enter correct 6-digit code on `/verify-otp`. Confirm receipt of access and refresh JWT tokens and navigation to `/dashboard`.
- [ ] **5 Wrong Attempts Lockout**: Enter 5 invalid codes on `/verify-otp`. Confirm error response `"Too many incorrect attempts. Try again later."` (HTTP 423/400) and log entry under `AUTH_OTP_LOCKED_OUT` for 15 minutes.
- [ ] **Account Enumeration Safety**: Request OTP for both registered and unregistered email addresses. Confirm identical API response times and generic user feedback.

---

## 2. Security Headers & CORS
- [ ] **CORS Origin Check**: Dispatch a request from `http://localhost:3000`. Confirm `Access-Control-Allow-Origin: http://localhost:3000`.
- [ ] **CORS Rejection**: Dispatch a request from an unauthorized origin. Confirm cross-origin request is blocked.
- [ ] **Security Headers**: Inspect HTTP response headers on any API response and confirm presence of:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `X-XSS-Protection: 1; mode=block`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Content-Security-Policy: default-src 'self'; frame-ancestors 'none';`

---

## 3. Observability & Sentry
- [ ] **Sentry DSN**: Confirm Sentry SDK initializes cleanly when `SENTRY_DSN` environment variable is provided.
- [ ] **Request Correlation**: Verify all application log entries include `requestId=<uuid>`.

---

## 4. Mobile Accessibility & Degraded UX
- [ ] **VoiceOver / TalkBack**: Enable VoiceOver (iOS) or TalkBack (Android). Navigate through Login, Dashboard, Watchlists, and Symbol Detail. Confirm all controls announce meaningful labels and hints.
- [ ] **1.3x Text Scaling**: Set system font size to 130%. Open Dashboard, Watchlists, Symbol Detail, and Portfolio. Confirm price tiles, cards, and buttons do not clip text.
- [ ] **Offline / Degraded Banner**: Disconnect network connection while on Dashboard, Watchlists, Symbol Detail, Alerts, or Portfolio. Confirm production degraded banner displays screen-specific message without crash.
