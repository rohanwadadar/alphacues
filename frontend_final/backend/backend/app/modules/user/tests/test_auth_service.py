from __future__ import annotations

import uuid
from datetime import timedelta
from unittest.mock import patch

import pytest
from sqlalchemy import select

from app.modules.user.models import OtpToken, UserSession
from app.modules.user.service import (
    MAX_OTP_ATTEMPTS,
    AuthService,
    generate_otp_code,
    hash_secret,
    normalize_email,
    utcnow,
    verify_secret,
)
from app.shared.db import db
from app.shared.exceptions import (
    OtpChallengeNotFoundError,
    OtpExpiredError,
    OtpInvalidError,
    OtpLockedError,
    UnauthorizedError,
)


@pytest.fixture
def auth_service(app, fake_email_sender):
    return AuthService(email_sender=fake_email_sender)


def test_normalize_email_unicode_and_whitespace():
    assert normalize_email("  User@Example.COM  ") == "user@example.com"
    assert normalize_email("café@example.com") == "café@example.com"


def test_otp_hash_verification(app):
    with app.app_context():
        code = "123456"
        stored = hash_secret(code)
        assert verify_secret(code, stored)
        assert not verify_secret("654321", stored)


def test_send_otp_and_verify_success(auth_service, fake_email_sender):
    result = auth_service.send_otp("user@example.com")
    challenge_id = uuid.UUID(result["otpChallengeId"])
    otp_code = fake_email_sender.last_otp_for("user@example.com")
    assert otp_code is not None
    assert result["emailMasked"] == "u***@example.com"
    assert result["expiresInSeconds"] == 300

    tokens = auth_service.verify_otp(
        email="user@example.com",
        challenge_id=challenge_id,
        otp_code=otp_code,
    )
    assert tokens["accessToken"]
    assert tokens["refreshToken"]
    assert tokens["expiresInSeconds"] == 900
    assert tokens["user"]["email"] == "user@example.com"
    assert isinstance(tokens["user"]["userId"], str)
    assert tokens["user"]["name"] is None
    assert tokens["user"]["avatarUrl"] is None


def test_wrong_otp_fails(auth_service, fake_email_sender):
    result = auth_service.send_otp("wrong@example.com")
    challenge_id = uuid.UUID(result["otpChallengeId"])

    with pytest.raises(OtpInvalidError):
        auth_service.verify_otp(
            email="wrong@example.com",
            challenge_id=challenge_id,
            otp_code="000000",
        )


def test_expired_otp_returns_otp_expired(auth_service, app):
    send_result = auth_service.send_otp("expired@example.com")
    challenge_id = uuid.UUID(send_result["otpChallengeId"])
    challenge = db.session.scalar(
        select(OtpToken).where(OtpToken.challenge_id == challenge_id)
    )
    challenge.expires_at = utcnow() - timedelta(seconds=1)
    db.session.commit()

    with pytest.raises(OtpExpiredError):
        auth_service.verify_otp(
            email="expired@example.com",
            challenge_id=challenge_id,
            otp_code="123456",
        )


def test_resend_invalidates_previous_challenge(auth_service, fake_email_sender):
    first = auth_service.send_otp("resend@example.com")
    first_id = uuid.UUID(first["otpChallengeId"])
    first_code = fake_email_sender.last_otp_for("resend@example.com")

    second = auth_service.send_otp("resend@example.com")
    second_id = uuid.UUID(second["otpChallengeId"])
    second_code = fake_email_sender.last_otp_for("resend@example.com")

    with pytest.raises(OtpExpiredError):
        auth_service.verify_otp(
            email="resend@example.com",
            challenge_id=first_id,
            otp_code=first_code,
        )

    tokens = auth_service.verify_otp(
        email="resend@example.com",
        challenge_id=second_id,
        otp_code=second_code,
    )
    assert tokens["accessToken"]


def test_five_wrong_attempts_locks_challenge(auth_service, fake_email_sender):
    result = auth_service.send_otp("locked@example.com")
    challenge_id = uuid.UUID(result["otpChallengeId"])

    for attempt in range(MAX_OTP_ATTEMPTS - 1):
        with pytest.raises(OtpInvalidError):
            auth_service.verify_otp(
                email="locked@example.com",
                challenge_id=challenge_id,
                otp_code="000000",
            )

    with pytest.raises(OtpLockedError):
        auth_service.verify_otp(
            email="locked@example.com",
            challenge_id=challenge_id,
            otp_code="000000",
        )

    with pytest.raises(OtpLockedError):
        auth_service.verify_otp(
            email="locked@example.com",
            challenge_id=challenge_id,
            otp_code="000000",
        )


def test_refresh_token_rotation(auth_service, fake_email_sender):
    send_result = auth_service.send_otp("rotate@example.com")
    challenge_id = uuid.UUID(send_result["otpChallengeId"])
    otp_code = fake_email_sender.last_otp_for("rotate@example.com")
    initial = auth_service.verify_otp(
        email="rotate@example.com",
        challenge_id=challenge_id,
        otp_code=otp_code,
    )
    old_refresh = initial["refreshToken"]

    rotated = auth_service.refresh_tokens(old_refresh)
    assert rotated["accessToken"] != initial["accessToken"]
    assert rotated["refreshToken"] != old_refresh

    with pytest.raises(UnauthorizedError):
        auth_service.refresh_tokens(old_refresh)

    revoked_sessions = db.session.scalars(
        select(UserSession).where(UserSession.revoked_at.is_not(None))
    ).all()
    assert len(revoked_sessions) >= 1


@patch("app.modules.user.service.generate_otp_code", return_value="123456")
def test_generate_otp_is_six_digits(_mocked):
    with patch("app.modules.user.service.secrets.randbelow", return_value=123456):
        assert generate_otp_code() == "123456"


def test_unknown_challenge_not_found(auth_service):
    with pytest.raises(OtpChallengeNotFoundError):
        auth_service.verify_otp(
            email="missing@example.com",
            challenge_id=uuid.uuid4(),
            otp_code="123456",
        )
