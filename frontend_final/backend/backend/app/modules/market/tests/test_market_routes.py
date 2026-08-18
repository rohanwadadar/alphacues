from __future__ import annotations

import pytest

BAR_FIELDS = {
    "timeStamp",
    "openPrice",
    "highPrice",
    "lowPrice",
    "closePrice",
    "volume",
}
FORBIDDEN_BAR_FIELDS = {"timeframe", "timestamp", "open", "high", "low", "close"}


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "market-user@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("market-user@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "market-user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    access_token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {access_token}"}


def test_quote_success(client, auth_headers):
    response = client.get("/api/v1/market/quote?symbol=AAPL", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    assert body["success"] is True
    assert body["data"]["symbol"] == "AAPL"
    assert isinstance(body["data"]["lastPrice"], (int, float))


def test_bars_shape(client, auth_headers):
    response = client.get(
        "/api/v1/market/bars?symbol=AAPL&timeframe=1day&range=1M",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["data"]["symbol"] == "AAPL"
    assert isinstance(body["data"]["bars"], list)
    for bar in body["data"]["bars"]:
        assert set(bar.keys()) == BAR_FIELDS
        assert not FORBIDDEN_BAR_FIELDS.intersection(bar.keys())


def test_bars_invalid_timeframe_1D(client, auth_headers):
    response = client.get(
        "/api/v1/market/bars?symbol=AAPL&timeframe=1D&range=1M",
        headers=auth_headers,
    )
    assert response.status_code == 422
    body = response.get_json()
    assert body["error"]["code"] == "VALIDATION_ERROR"


def test_bars_invalid_timeframe_1Min_capitalised(client, auth_headers):
    response = client.get(
        "/api/v1/market/bars?symbol=AAPL&timeframe=1Min&range=1M",
        headers=auth_headers,
    )
    assert response.status_code == 422
    body = response.get_json()
    assert body["error"]["code"] == "VALIDATION_ERROR"


def test_snapshot_batch(client, auth_headers):
    response = client.get(
        "/api/v1/market/snapshot?symbols=AAPL,TSLA",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert isinstance(body["data"], list)
    for item in body["data"]:
        assert "symbol" in item
        assert "lastPrice" in item


def test_search_success(client, auth_headers):
    response = client.get(
        "/api/v1/market/search?q=apple",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert isinstance(body["data"], list)


def test_movers_gainers(client, auth_headers):
    response = client.get(
        "/api/v1/market/movers?sort=gainers&limit=5",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert isinstance(body["data"], list)
    assert len(body["data"]) <= 5


def test_fundamentals_success(client, auth_headers):
    response = client.get(
        "/api/v1/market/fundamentals?symbol=AAPL",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["data"]["symbol"] == "AAPL"


def test_dashboard_success(client, auth_headers):
    response = client.get("/api/v1/dashboard", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    assert "gainers" in body["data"]
    assert "losers" in body["data"]


def test_unauthenticated(client):
    response = client.get("/api/v1/market/quote?symbol=AAPL")
    assert response.status_code == 401
    body = response.get_json()
    assert body["error"]["code"] == "UNAUTHORIZED"
