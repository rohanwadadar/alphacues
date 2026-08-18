from __future__ import annotations

import pytest

from app.modules.watchlist.service import WatchlistService
from app.shared.exceptions import DuplicateSymbolError, NotFoundError, ValidationError


@pytest.fixture
def user_id(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "watchlist-service@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("watchlist-service@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "watchlist-service@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    return int(verify.get_json()["data"]["user"]["userId"])


@pytest.fixture
def other_user_id(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "other-watchlist@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("other-watchlist@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "other-watchlist@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    return int(verify.get_json()["data"]["user"]["userId"])


def test_add_symbol_duplicate_raises_duplicate_symbol_error(user_id):
    watchlist = WatchlistService.create_watchlist(user_id, "Tech Picks")
    WatchlistService.add_symbol(user_id, watchlist.watchlist_id, "AAPL")

    with pytest.raises(DuplicateSymbolError) as exc_info:
        WatchlistService.add_symbol(user_id, watchlist.watchlist_id, "AAPL")

    assert exc_info.value.code == "DUPLICATE_SYMBOL"
    assert exc_info.value.status_code == 409


def test_accessing_another_users_watchlist_raises_not_found(user_id, other_user_id):
    watchlist = WatchlistService.create_watchlist(user_id, "Private List")

    with pytest.raises(NotFoundError) as exc_info:
        WatchlistService.get_watchlist(other_user_id, watchlist.watchlist_id)

    assert exc_info.value.code == "NOT_FOUND"


def test_add_symbol_rejects_invalid_symbol_formats(user_id):
    watchlist = WatchlistService.create_watchlist(user_id, "Tech Picks")

    with pytest.raises(ValidationError):
        WatchlistService.add_symbol(user_id, watchlist.watchlist_id, "aapl")

    with pytest.raises(ValidationError):
        WatchlistService.add_symbol(user_id, watchlist.watchlist_id, "123")
