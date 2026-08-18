import logging
import pytest
from app.shared.logging import (
    log_otp_failed,
    log_otp_lockout,
    log_otp_request,
    log_rate_limit_exceeded,
)


def test_auth_abuse_log_helpers_emit_expected_signals(caplog):
    caplog.set_level(logging.INFO)

    log_otp_request("u***@alphacues.com")
    assert "AUTH_OTP_REQUESTED" in caplog.text

    log_otp_failed("u***@alphacues.com", attempts_left=3)
    assert "AUTH_OTP_FAILED" in caplog.text
    assert "attempts_left=3" in caplog.text

    log_otp_lockout("u***@alphacues.com", lock_duration_minutes=15)
    assert "AUTH_OTP_LOCKED_OUT" in caplog.text
    assert "lock_duration_mins=15" in caplog.text

    log_rate_limit_exceeded("/api/v1/auth/verify-otp")
    assert "RATE_LIMITED" in caplog.text
    assert "status_code=429" in caplog.text
