from __future__ import annotations

import json
from pathlib import Path

import pytest

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "watchlist-user@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("watchlist-user@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "watchlist-user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    access_token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture
def other_auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "other-watchlist-user@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("other-watchlist-user@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "other-watchlist-user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    access_token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {access_token}"}


def _assert_envelope(body: dict) -> None:
    assert isinstance(body["success"], bool)
    assert "data" in body
    assert "error" in body
    assert isinstance(body["requestId"], str)


def test_create_watchlist(client, auth_headers):
    response = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    assert response.status_code == 201
    body = response.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert body["data"]["name"] == "Tech Picks"
    assert body["data"]["symbolCount"] == 0
    assert isinstance(body["data"]["watchlistId"], str)


def test_list_watchlists_returns_only_authenticated_user_watchlists(
    client, auth_headers, other_auth_headers
):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "My List"},
    )
    assert create.status_code == 201

    client.post(
        "/api/v1/watchlist",
        headers=other_auth_headers,
        json={"name": "Other List"},
    )

    response = client.get("/api/v1/watchlist", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)
    assert len(body["data"]["watchlists"]) == 1
    assert body["data"]["watchlists"][0]["name"] == "My List"


def test_rename_watchlist(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Old Name"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]

    response = client.put(
        f"/api/v1/watchlist/{watchlist_id}",
        headers=auth_headers,
        json={"name": "New Name"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["data"]["name"] == "New Name"


def test_delete_watchlist_removes_watchlist_and_items(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "To Delete"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]
    client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )

    response = client.delete(
        f"/api/v1/watchlist/{watchlist_id}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.get_json()["data"] == {}

    detail = client.get(
        f"/api/v1/watchlist/{watchlist_id}",
        headers=auth_headers,
    )
    assert detail.status_code == 404
    assert detail.get_json()["error"]["code"] == "NOT_FOUND"


def test_add_symbol_success(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]

    response = client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )
    assert response.status_code == 201
    body = response.get_json()
    assert body["data"]["symbol"] == "AAPL"
    assert "addedAt" in body["data"]


def test_add_duplicate_symbol_returns_409(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]
    client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )

    response = client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )
    assert response.status_code == 409
    body = response.get_json()
    assert body["error"]["code"] == "DUPLICATE_SYMBOL"


def test_remove_symbol(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]
    client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )

    response = client.delete(
        f"/api/v1/watchlist/{watchlist_id}/items/AAPL",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.get_json()["data"] == {}


def test_unauthenticated_requests_return_401(client):
    endpoints = [
        ("GET", "/api/v1/watchlist"),
        ("POST", "/api/v1/watchlist"),
        ("GET", "/api/v1/watchlist/1"),
        ("PUT", "/api/v1/watchlist/1"),
        ("DELETE", "/api/v1/watchlist/1"),
        ("POST", "/api/v1/watchlist/1/items"),
        ("DELETE", "/api/v1/watchlist/1/items/AAPL"),
    ]
    for method, path in endpoints:
        response = client.open(path, method=method, json={"name": "Test"})
        assert response.status_code == 401, f"{method} {path}"
        assert response.get_json()["error"]["code"] == "UNAUTHORIZED"


def test_watchlist_detail_includes_quotes(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]
    client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )

    response = client.get(
        f"/api/v1/watchlist/{watchlist_id}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["data"]["watchlistId"] == watchlist_id
    assert len(body["data"]["items"]) == 1
    item = body["data"]["items"][0]
    assert item["symbol"] == "AAPL"
    assert isinstance(item["lastPrice"], (int, float))
    assert item["asOf"] is not None


def test_watchlist_list_contract_shape(client, auth_headers):
    client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    response = client.get("/api/v1/watchlist", headers=auth_headers)
    body = response.get_json()
    fixture = json.loads((CONTRACTS_DIR / "watchlist_list.json").read_text())

    for key in fixture["data"]:
        assert key in body["data"]
    watchlist = body["data"]["watchlists"][0]
    for key in fixture["data"]["watchlists"][0]:
        assert key in watchlist


def test_watchlist_detail_contract_shape(client, auth_headers):
    create = client.post(
        "/api/v1/watchlist",
        headers=auth_headers,
        json={"name": "Tech Picks"},
    )
    watchlist_id = create.get_json()["data"]["watchlistId"]
    client.post(
        f"/api/v1/watchlist/{watchlist_id}/items",
        headers=auth_headers,
        json={"symbol": "AAPL"},
    )

    response = client.get(
        f"/api/v1/watchlist/{watchlist_id}",
        headers=auth_headers,
    )
    body = response.get_json()
    fixture = json.loads((CONTRACTS_DIR / "watchlist_detail.json").read_text())

    for key in fixture["data"]:
        assert key in body["data"]
    item = body["data"]["items"][0]
    for key in fixture["data"]["items"][0]:
        assert key in item
