# AlphaCues Testing Instructions (Phase 3 & 4)

## Architecture Overview
The AlphaCues frontend has been successfully migrated to the `alphacues_final` directory. It uses the visual identity and structural layout (Splash Screen, Floating Bottom Navigation) of the `trading_app2026-feb` UI reference, while continuing to integrate seamlessly with the original AlphaCues backend running locally on port `5000`.

## 1. Starting the Environment

**Backend:**
Ensure the Flask backend is running on `127.0.0.1:5000`. (It is already running in Task 441).
If you need to restart it:
```bash
cd C:\Users\Admin\Desktop\ALPHA\alphacues-mvpapi-cursor-phase-1-backend-skeleton
.\.venv\Scripts\python.exe wsgi.py
```

**Frontend:**
Run the newly migrated frontend on the web server (Port 8080):
```bash
cd C:\Users\Admin\Desktop\ALPHA\alphacues_final
flutter run -d web-server --web-port 8080
```

## 2. Visual Walkthrough & Features to Test

### **A. App Intro / Splash Screen**
1. Open your browser and navigate to `http://localhost:8080`.
2. **Verify:** You will immediately see the newly integrated AlphaCues splash screen (purple gradient, floating 'AC' logo, and "Smart Trading. Simplified.").
3. Wait ~2.8 seconds, the app will automatically route you to the Dashboard (or Login screen if not authenticated).

### **B. Authentication (OTP)**
1. If presented with the Login screen, enter your email.
2. Check the backend terminal (Task 441) for the 6-digit OTP code.
3. Enter the OTP code to log in.

### **C. Floating Bottom Navigation Bar**
1. Look at the bottom of the screen.
2. **Verify:** The new Bottom Navigation Bar is a floating black capsule (matching `trading_app2026-feb` perfectly).
3. Tap on the different tabs: Home, Watchlists, Alerts, Portfolio.
4. **Verify:** The views swap instantly while the floating nav bar persists smoothly.

### **D. Phase 3 & 4 Dashboard UI (Cards, Shadows, White Theme)**
1. Navigate to the **Dashboard** (Home).
2. **Verify:** The white/purple/grey modern theme is applied.
3. **Verify:** Portfolio balance card uses the bold hero styling with the privacy eye toggle (tap to hide/show balance).
4. Navigate to **Watchlists** or **Alerts**.
5. **Verify:** Rows are styled as floating card containers with pill badges (green for uptrend, red for downtrend, star icons).

## 3. Real-time Socket Verification
1. Ensure the Dashboard displays live market data (symbols updating their prices).
2. The WebSocket client connects instantly after login. If it disconnects, a "Stale Data" banner will appear at the top.

## 4. Run Automated Tests
If you want to verify the structural integrity of the codebase:
```bash
cd C:\Users\Admin\Desktop\ALPHA\alphacues_final
flutter test
```
All tests (including accessibility, dashboard, and watchlist tests) are configured to pass.
