from __future__ import annotations

import json
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import pytest
from sqlalchemy import select

from app.modules.portfolio.models import Position

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "portfolio-routes@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("portfolio-routes@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "portfolio-routes@example.com",
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
    assert isinstance(body["meta"]["requestId"], str)
    assert body["meta"]["apiVersion"] == "1"


def test_record_buy_event_creates_position(client, auth_headers):
    response = client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 188.5,
            "volume": 10,
        },
    )
    assert response.status_code == 201
    body = response.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert body["data"]["symbol"] == "AAPL"
    assert body["data"]["action"] == "BUY"
    assert body["data"]["volume"] == 10

    summary = client.get("/api/v1/portfolio", headers=auth_headers)
    assert summary.status_code == 200


def test_record_sell_event_reduces_position(client, auth_headers):
    client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100.0,
            "volume": 10,
        },
    )
    sell = client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "SELL",
            "price": 130.0,
            "volume": 4,
        },
    )
    assert sell.status_code == 201
    assert sell.get_json()["data"]["action"] == "SELL"


def test_record_event_rejects_old_time_stamp(client, auth_headers):
    from sqlalchemy import func, select

    from app.modules.portfolio.models import PortfolioEvent
    from app.shared.db import db

    before_count = db.session.scalar(select(func.count()).select_from(PortfolioEvent))

    response = client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100,
            "volume": 1,
            "time_stamp": "2000-01-01T00:00:00Z",
        },
    )
    assert response.status_code == 422
    body = response.get_json()
    assert body["success"] is False
    assert body["error"]["code"] == "VALIDATION_ERROR"
    assert "editable window" in body["error"]["message"].lower()

    after_count = db.session.scalar(select(func.count()).select_from(PortfolioEvent))
    assert after_count == before_count


def test_list_transactions_returns_paginated_ledger(client, auth_headers):
    for idx in range(3):
        client.post(
            "/api/v1/portfolio/event",
            headers=auth_headers,
            json={
                "symbol": "AAPL",
                "action": "BUY",
                "price": 100.0 + idx,
                "volume": 1,
            },
        )

    response = client.get(
        "/api/v1/portfolio/transactions?limit=2",
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)
    assert len(body["data"]["transactions"]) == 2
    assert "meta" in body
    assert "nextCursor" in body["meta"]
    assert body["meta"]["nextCursor"] is not None

    page_two = client.get(
        f"/api/v1/portfolio/transactions?limit=2&cursor={body['meta']['nextCursor']}",
        headers=auth_headers,
    )
    assert page_two.status_code == 200
    assert len(page_two.get_json()["data"]["transactions"]) == 1


def test_list_transactions_honors_page_size_query_param(client, auth_headers):
    for idx in range(3):
        client.post(
            "/api/v1/portfolio/event",
            headers=auth_headers,
            json={
                "symbol": "AAPL",
                "action": "BUY",
                "price": 100.0 + idx,
                "volume": 1,
            },
        )

    page_one = client.get(
        "/api/v1/portfolio/transactions?page=1&pageSize=1",
        headers=auth_headers,
    )
    assert page_one.status_code == 200
    body = page_one.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert len(body["data"]["transactions"]) == 1
    assert body["meta"]["nextCursor"] is not None

    page_two_items = client.get(
        "/api/v1/portfolio/transactions?pageSize=2",
        headers=auth_headers,
    )
    assert page_two_items.status_code == 200
    assert len(page_two_items.get_json()["data"]["transactions"]) == 2


def test_portfolio_summary_returns_correct_shape(client, auth_headers):
    client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100.0,
            "volume": 10,
        },
    )

    response = client.get("/api/v1/portfolio", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)

    fixture = json.loads((CONTRACTS_DIR / "portfolio_summary.json").read_text())
    for key in fixture["data"]:
        assert key in body["data"], f"Missing contract field: {key}"


def test_edit_and_delete_event_routes(client, auth_headers):
    create = client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100.0,
            "volume": 10,
        },
    )
    event_id = create.get_json()["data"]["eventId"]

    update = client.put(
        f"/api/v1/portfolio/event/{event_id}",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 110.0,
            "volume": 8,
        },
    )
    assert update.status_code == 200
    assert update.get_json()["data"]["volume"] == 8

    delete = client.delete(
        f"/api/v1/portfolio/event/{event_id}",
        headers=auth_headers,
    )
    assert delete.status_code == 200
    assert delete.get_json()["data"] is None


def test_update_event_preserves_time_stamp_when_omitted(client, auth_headers):
    t1 = "2026-06-17T01:34:01Z"
    t2 = "2026-06-17T01:35:11Z"
    t3 = "2026-06-17T01:35:37Z"

    first = client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100.0,
            "volume": 10,
            "time_stamp": t1,
        },
    )
    event_id = first.get_json()["data"]["eventId"]

    client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 120.0,
            "volume": 5,
            "time_stamp": t2,
        },
    )
    client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "SELL",
            "price": 130.0,
            "volume": 5,
            "time_stamp": t3,
        },
    )

    update = client.put(
        f"/api/v1/portfolio/event/{event_id}",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 90.0,
            "volume": 10,
        },
    )
    assert update.status_code == 200
    body = update.get_json()
    assert body["data"]["time_stamp"] == t1

    from app.shared.db import db

    position = db.session.scalar(
        select(Position).where(Position.symbol == "AAPL")
    )
    assert position is not None
    assert position.volume == 10
    assert position.total_price == Decimal("1000.000000")


def test_portfolio_routes_require_auth(client):
    response = client.get("/api/v1/portfolio")
    assert response.status_code == 401
    body = response.get_json()
    assert body["success"] is False
    assert body["error"]["code"] in {"UNAUTHORIZED", "TOKEN_EXPIRED"}


def test_portfolio_history_returns_snapshots(client, auth_headers):
    client.post(
        "/api/v1/portfolio/event",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "action": "BUY",
            "price": 100.0,
            "volume": 5,
        },
    )

    response = client.get("/api/v1/portfolio/history", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)
    assert len(body["data"]["history"]) >= 1
    snapshot = body["data"]["history"][0]
    assert "time_stamp" in snapshot
    assert "symbol" in snapshot
    assert "quantity" in snapshot
    assert "total_price" in snapshot
