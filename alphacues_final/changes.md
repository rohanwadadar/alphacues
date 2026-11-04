# AlphaCues Strategy Builder Change Log

## [v2.2.0] - Realistic Profile Page & Real-Time Backend Govt ID KYC Integration (Current Version)
- **Profile Header & Badges**:
  - Added camera avatar picker, display name, email, bio, and "Last Updated" timestamp.
  - Added verified badges: **Govt ID Verified** (blue badge), **Verified Investor** (green checkmark), **Pro Level 12**, and Trading Style.
- **Personal Information & Edit Profile Page (`EditProfileScreen`)**:
  - Replicated exact features and structure from `trading_app2026-feb`.
  - Includes:
    - **Personal Information**: Gender, Date of Birth picker, Marital Status, Income Range.
    - **Contact Information**: Name, Email (Verified), Phone Number (Verified), Phone Type.
    - **Professional Information**: Occupation, Source of Funds.
    - **Investment Information**: Experience, Product Types, Frequency, Objectives.
    - **Primary & Secondary Addresses**: Editable House No, Street, City, State, ZIP, Country, Address Type, Citizenship.
    - **Identity & Govt ID Card Information (KYC)**: Identity Type (Govt ID Card / Aadhaar, Passport, SSN, Driver License, National ID), Govt ID Number (with show/hide mask toggle).
- **Digitized Government Identity Card Modal (`GovtIdCardModal`)**:
  - Interactive digitized Govt ID card view displaying security badges, digitized photo avatar, cardholder details, ID number, and KYC compliance checklist.
- **Backend Realtime Synchronization**:
  - Added backend SQLAlchemy user model columns, `UpdateProfileSchema` validation, and `PUT /api/v1/auth/me` route for real-time profile & KYC persistence.

## [v2.1.0] - New Account Portfolio & Welcoming Guide Optimization
- **New Account Clean Slate**:
  - Removed default position seeding on user registration in backend (`app/modules/user/service.py`).
  - New accounts now start with a 100% clear portfolio ($0.00 total valuation, 0 positions, 0 transactions).
  - Portfolio screen displays a clean empty state card with clear instructions for adding the first BUY transaction.
- **Conditional Welcoming Instructions**:
  - Added `isNewUser` flag to backend auth responses and Flutter `AuthUser` model.
  - When a **NEW account** registers (`isNewUser == true`), `hasCompletedOnboarding` is set to `false`, displaying the `OnboardingGuideModal` welcoming instruction guide to guide the new user.
  - When an **OLDER/existing profile** logs in or resumes session (`isNewUser == false`), `hasCompletedOnboarding` is set to `true`, suppressing all welcoming instruction popups.

## [v2.0.0] - Redesign Strategy Builder Screen & Popup Modals

### Added & Redesigned Features:
1. **Back Navigation Button**: Added back navigation arrow (`Icons.arrow_back_rounded`) to `AppBar` allowing seamless navigation.
2. **Add New Strategy Popup Modal**:
   - Removed the inline "Add a new strategy" box from the main scroll view.
   - Added a sleek **`+ Add Strategy`** button in the Saved Strategies section header.
   - Clicking opens a bottom sheet modal where users enter Strategy Name and configure categorized filters:
     - **Strategy Types**: Breakout, Growth, Value, Momentum, Dividend chips.
     - **Fundamentals**: Price, Market Cap ($B), Daily Change (%), P/E Ratio.
     - **Technical Indicators**: Avg Volume, Volatility, Relative Volume, Current Volume, RSI(14).
     - **Moving Averages**: 50 MA, 200 MA criteria.
3. **Saved Strategies Display Optimization**:
   - Direct on-page strategies limited to **Max 3 items** for optimal screen space.
   - Added **"See All"** button that opens a popup modal with all saved strategies, complete with search, edit, delete, and tap-to-select functionality.
4. **Interactive Filters Modal & Green Color Highlighting**:
   - Added a dedicated **Filters** button beside the **Sort** row.
   - Opening the Filters modal highlights active/applied filters in **Green color**, while unselected/off filters are styled with subdued off-colors.
5. **Enhanced Screener Stock Cards (`ScreenerResultCard`)**:
   - Stock card now displays Symbol, Company Full Name (in small subtle text), Price, Day Change %, Market Cap, Volume (e.g. `Vol: 2.4M`), Exchange badge, and Quick Add button.

---

## [v1.0.0] - Initial Strategy Builder Design (Backup saved in `strategy_screen_v1.dart`)
- Inline "Add a new strategy" box with strategy name text field and run/save buttons.
- Saved strategies horizontal/vertical list.
- Basic filter modal and results list.
