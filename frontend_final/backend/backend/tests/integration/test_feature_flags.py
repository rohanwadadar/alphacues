"""Integration tests for the feature-flag admin endpoints and gating behaviour.

Three tests as specified in Phase 3 Task 20:

1. test_disabled_screener_returns_403
   Flip enable_screener to False, hit a screener-gated route, confirm
   HTTP 403 with error.code == "FEATURE_DISABLED".

2. test_flag_flip_reflects_without_deploy
   Enable a flag through the admin PATCH endpoint mid-test and confirm the
   very next request to the gated route reflects the new value (proves the
   cache-invalidation path, not just the DB update).

3. test_admin_list_flags_returns_required_flags
   GET /api/v1/admin/flags returns HTTP 200 and all six required flag keys.

Notes
-----
- require_admin is monkeypatched to a no-op pass-through for every test in
  this module because the real admin-auth mechanism is a stub (deny-by-default
  by design — see TODO(admin-auth) in shared/auth.py).  The monkeypatch is
  intentional and isolates these tests from the unresolved auth decision.
- The screener route is used as the gated endpoint (as the plan specifies).
  A FakeMarketAdapter is injected so the test does not need real market data.
"""
from __future__ import annotations

from functools import wraps
from typing import Any

import pytest

from app.shared.feature_flags import FeatureFlag
from app.shared.db import db

# ---------------------------------------------------------------------------
# Required flag keys (closed set from Task 3 seed)
# ---------------------------------------------------------------------------
REQUIRED_FLAG_KEYS = {
    "use_microservice_auth",
    "use_microservice_portfolio",
    "use_microservice_market",
    "enable_live_trading",
    "enable_simulator",
    "enable_screener",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _seed_flags(session, *, enable_screener: bool = True) -> None:
    """Insert all required flags; caller controls enable_screener value."""
    session.query(FeatureFlag).delete()
    session.commit()
    for key in REQUIRED_FLAG_KEYS:
        flag = FeatureFlag(
            flag_key=key,
            is_enabled=(True if key != "enable_screener" else enable_screener),
            description=f"Test seed: {key}",
        )
        session.add(flag)
    session.commit()


def _noop_admin_guard(func):
    """Passthrough replacement for require_admin used in all tests here."""
    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any):
        return func(*args, **kwargs)
    return wrapper  # type: ignore[return-value]


def _make_auth_token(client, fake_email_sender) -> str:
    """Return a valid JWT by going through the OTP flow."""
    # send-otp
    r = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "testuser@example.com"},
    )
    assert r.status_code in (200, 201), f"send-otp failed: {r.json}"

    otp = fake_email_sender.last_otp_for("testuser@example.com")

    # verify-otp
    data = r.json["data"]
    challenge_id = data.get("otpChallengeId") or data.get("challengeId")
    rv = client.post(
        "/api/v1/auth/verify-otp",
        json={"otpChallengeId": challenge_id, "challengeId": challenge_id, "otp": otp},
    )
    assert rv.status_code == 200, f"verify-otp failed: {rv.json}"
    return rv.json["data"]["accessToken"]


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
class _FakeQuote:
    lastPrice = 100.0
    changePercent = 0.5
    changeAmount = 0.5


class _FakeFundamentals:
    symbol = "AAPL"
    name = "Apple Inc."
    marketCap = 3_000_000_000_000.0
    peRatio = 28.0
    eps = 6.5
    dividendYield = 0.005
    fiftyTwoWeekHigh = 200.0
    fiftyTwoWeekLow = 140.0
    exchange = "NASDAQ"


class FakeMarketAdapter:
    def get_quote(self, symbol: str) -> _FakeQuote:
        return _FakeQuote()

    def get_fundamentals(self, symbol: str) -> _FakeFundamentals:
        return _FakeFundamentals()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
class TestFeatureFlagIntegration:
    """Integration tests for Task 20 — feature-flag admin and gating."""

    def test_disabled_screener_returns_403(self, app, client, fake_email_sender, monkeypatch):
        """Disabled enable_screener flag → screener route returns 403 FEATURE_DISABLED."""
        # Patch require_admin so admin endpoints are accessible in tests.
        monkeypatch.setattr(
            "app.shared.auth.require_admin",
            _noop_admin_guard,
        )
        monkeypatch.setattr(
            "app.modules.admin.routes.require_admin",
            _noop_admin_guard,
        )

        with app.app_context():
            # Seed flags with screener DISABLED.
            _seed_flags(db.session, enable_screener=False)

            # Inject fake market adapter so we don't need real API keys.
            app.extensions["market_data_adapter"] = FakeMarketAdapter()

        # Obtain a valid auth token.
        token = _make_auth_token(client, fake_email_sender)
        headers = {"Authorization": f"Bearer {token}"}

        # Hit the screener run endpoint — must return 403 FEATURE_DISABLED.
        rv = client.post(
            "/api/v1/screener/run",
            json={"filters": {}, "sort_by": "marketCap", "sort_order": "desc"},
            headers=headers,
        )
        assert rv.status_code == 403, (
            f"Expected 403 for disabled screener, got {rv.status_code}: {rv.json}"
        )
        body = rv.json
        assert body["success"] is False
        assert body["error"]["code"] == "FEATURE_DISABLED"
        assert body["meta"]["apiVersion"] == "1"
        assert "requestId" in body["meta"]

    def test_flag_flip_reflects_without_deploy(self, app, client, fake_email_sender, monkeypatch):
        """Admin PATCH enable_screener=True → next screener request sees the change.

        This is the cache-invalidation proof test: the flag is set to False in
        the DB, then flipped to True via the admin endpoint, and the very next
        screener request must succeed (HTTP 200) — proving that the PATCH path
        immediately invalidated the Redis cache rather than leaving a stale value.
        """
        monkeypatch.setattr("app.shared.auth.require_admin", _noop_admin_guard)
        monkeypatch.setattr("app.modules.admin.routes.require_admin", _noop_admin_guard)

        with app.app_context():
            _seed_flags(db.session, enable_screener=False)
            app.extensions["market_data_adapter"] = FakeMarketAdapter()

        token = _make_auth_token(client, fake_email_sender)
        headers = {"Authorization": f"Bearer {token}"}

        # Confirm screener is disabled before the flip.
        pre_flip = client.post(
            "/api/v1/screener/run",
            json={"filters": {}, "sort_by": "marketCap", "sort_order": "desc"},
            headers=headers,
        )
        assert pre_flip.status_code == 403, (
            f"Pre-flip should be 403, got {pre_flip.status_code}"
        )

        # Flip the flag via the admin endpoint (mid-test — no deploy).
        patch_rv = client.patch(
            "/api/v1/admin/flags/enable_screener",
            json={"is_enabled": True},
            headers=headers,
        )
        assert patch_rv.status_code == 200, (
            f"Admin PATCH failed: {patch_rv.status_code} {patch_rv.json}"
        )
        patched_body = patch_rv.json
        assert patched_body["data"]["isEnabled"] is True

        # Immediately hit the screener again — must now succeed (200).
        post_flip = client.post(
            "/api/v1/screener/run",
            json={"filters": {}, "sort_by": "marketCap", "sort_order": "desc"},
            headers=headers,
        )
        assert post_flip.status_code == 200, (
            f"Post-flip screener should be 200 (flag enabled), "
            f"got {post_flip.status_code}: {post_flip.json}"
        )
        assert post_flip.json["success"] is True

    def test_admin_list_flags_returns_required_flags(self, app, client, fake_email_sender, monkeypatch):
        """GET /api/v1/admin/flags returns 200 and all six required flag keys."""
        monkeypatch.setattr("app.shared.auth.require_admin", _noop_admin_guard)
        monkeypatch.setattr("app.modules.admin.routes.require_admin", _noop_admin_guard)

        with app.app_context():
            _seed_flags(db.session, enable_screener=True)

        token = _make_auth_token(client, fake_email_sender)
        headers = {"Authorization": f"Bearer {token}"}

        rv = client.get("/api/v1/admin/flags", headers=headers)
        assert rv.status_code == 200, (
            f"Expected 200 from admin/flags, got {rv.status_code}: {rv.json}"
        )
        body = rv.json
        assert body["success"] is True
        assert body["error"] is None
        assert body["meta"]["apiVersion"] == "1"
        assert "requestId" in body["meta"]

        returned_keys = {f["flagKey"] for f in body["data"]["flags"]}
        missing = REQUIRED_FLAG_KEYS - returned_keys
        assert not missing, (
            f"Admin flag list is missing required keys: {missing}"
        )
