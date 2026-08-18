from __future__ import annotations

import json
import uuid
from pathlib import Path

import pytest
from sqlalchemy import select

from app.modules.user.models import User, UserSession
from app.shared.db import db

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


def _assert_envelope(body: dict) -> None:
    assert isinstance(body["success"], bool)
    assert "data" in body
    assert "error" in body
    assert isinstance(body["meta"]["requestId"], str)
    assert body["meta"]["requestId"]
    assert body["meta"]["apiVersion"] == "1"


def test_send_otp_success(client, fake_email_sender):
    response = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "user@example.com"},
    )
    assert response.status_code == 201
    body = response.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert body["error"] is None
    assert body["data"]["otpChallengeId"]
    assert body["data"]["emailMasked"] == "u***@example.com"
    assert body["data"]["expiresInSeconds"] == 300
    uuid.UUID(body["data"]["otpChallengeId"])
    assert fake_email_sender.last_otp_for("user@example.com") is not None


def test_verify_otp_success(client, fake_email_sender):
    send = client.post("/api/v1/auth/send-otp", json={"email": "user@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("user@example.com")

    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert body["data"]["accessToken"]
    assert body["data"]["refreshToken"]
    assert body["data"]["expiresInSeconds"] == 900
    assert body["data"]["user"]["email"] == "user@example.com"
    assert isinstance(body["data"]["user"]["userId"], str)
    assert "name" in body["data"]["user"]
    assert "avatarUrl" in body["data"]["user"]
    assert body["data"]["user"]["name"] is None
    assert body["data"]["user"]["avatarUrl"] is None


def test_refresh_rotates_tokens(client, fake_email_sender):
    send = client.post("/api/v1/auth/send-otp", json={"email": "refresh@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("refresh@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "refresh@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    refresh_token = verify.get_json()["data"]["refreshToken"]

    response = client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": refresh_token},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["data"]["accessToken"]
    assert body["data"]["refreshToken"] != refresh_token

    stale = client.post("/api/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert stale.status_code == 401
    assert stale.get_json()["error"]["code"] == "UNAUTHORIZED"


def test_logout_revokes_session(client, fake_email_sender):
    send = client.post("/api/v1/auth/send-otp", json={"email": "logout@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("logout@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "logout@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    refresh_token = verify.get_json()["data"]["refreshToken"]

    logout = client.post("/api/v1/auth/logout", json={"refreshToken": refresh_token})
    assert logout.status_code == 200
    assert logout.get_json()["data"] is None

    sessions = db.session.scalars(select(UserSession).join(User).where(User.email == "logout@example.com")).all()
    assert len(sessions) > 0
    assert all(session.revoked_at is not None for session in sessions)

    refresh = client.post("/api/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert refresh.status_code == 401


@pytest.mark.parametrize(
    "fixture_name,endpoint,payload_factory",
    [
        (
            "auth_send_otp_response.json",
            "/api/v1/auth/send-otp",
            lambda: {"email": "user@example.com"},
        ),
    ],
)
def test_contract_fixtures_match_shape(
    client, fake_email_sender, fixture_name, endpoint, payload_factory
):
    fixture = json.loads((CONTRACTS_DIR / fixture_name).read_text())
    response = client.post(endpoint, json=payload_factory())
    body = response.get_json()
    assert body["success"] == fixture["success"]
    assert body["error"] == fixture["error"]
    assert set(body["data"].keys()) == set(fixture["data"].keys())


def test_contract_verify_otp_success_fixture_keys(client, fake_email_sender):
    fixture = json.loads((CONTRACTS_DIR / "auth_verify_otp_response.json").read_text())
    send = client.post("/api/v1/auth/send-otp", json={"email": "user@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("user@example.com")
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    body = response.get_json()
    assert body["success"] == fixture["success"]
    assert body["error"] == fixture["error"]
    assert set(body["data"].keys()) == set(fixture["data"].keys())
    assert set(body["data"]["user"].keys()) == set(fixture["data"]["user"].keys())


def test_otp_invalid_contract(client, fake_email_sender):
    fixture = json.loads((CONTRACTS_DIR / "otp-invalid.json").read_text())
    send = client.post("/api/v1/auth/send-otp", json={"email": "invalid@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "invalid@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": "000000",
        },
    )
    body = response.get_json()
    assert response.status_code == 401
    assert body["success"] == fixture["success"]
    assert body["data"] is None
    assert body["error"]["code"] == fixture["error"]["code"]


def test_otp_expired_contract(client, fake_email_sender, app):
    from datetime import timedelta

    from app.modules.user.models import OtpToken
    from app.modules.user.service import utcnow

    fixture = json.loads((CONTRACTS_DIR / "otp-expired.json").read_text())
    send = client.post("/api/v1/auth/send-otp", json={"email": "expired@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    with app.app_context():
        challenge = db.session.scalar(
            select(OtpToken).where(OtpToken.challenge_id == uuid.UUID(challenge_id))
        )
        challenge.expires_at = utcnow() - timedelta(seconds=1)
        db.session.commit()

    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "expired@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": fake_email_sender.last_otp_for("expired@example.com"),
        },
    )
    body = response.get_json()
    assert response.status_code == 401
    assert body["success"] == fixture["success"]
    assert body["error"]["code"] == fixture["error"]["code"]


def test_otp_locked_contract(client, fake_email_sender):
    from app.modules.user.service import MAX_OTP_ATTEMPTS

    fixture = json.loads((CONTRACTS_DIR / "otp-locked.json").read_text())
    send = client.post("/api/v1/auth/send-otp", json={"email": "locked@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]

    for _ in range(MAX_OTP_ATTEMPTS - 1):
        client.post(
            "/api/v1/auth/verify-otp",
            json={
                "email": "locked@example.com",
                "otpChallengeId": challenge_id,
                "otpCode": "000000",
            },
        )

    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "locked@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": "000000",
        },
    )
    body = response.get_json()
    assert response.status_code == 429
    assert body["success"] == fixture["success"]
    assert body["error"]["code"] == fixture["error"]["code"]


def test_otp_challenge_not_found_contract(client):
    fixture = json.loads((CONTRACTS_DIR / "otp-challenge-not-found.json").read_text())
    client.post("/api/v1/auth/send-otp", json={"email": "user@example.com"})
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "user@example.com",
            "otpChallengeId": str(uuid.uuid4()),
            "otpCode": "123456",
        },
    )
    body = response.get_json()
    assert response.status_code == 404
    assert body["error"]["code"] == fixture["error"]["code"]
