from __future__ import annotations

import json
from decimal import Decimal
from pathlib import Path

import pytest

from app.modules.alerts.service import AlertEvaluationService, AlertsService

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "alerts-routes@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("alerts-routes@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "alerts-routes@example.com",
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
        json={"email": "other-alerts@example.com"},
    )
    challenge_id = send.get_json()["data"]["challengeId"]
    otp_code = fake_email_sender.last_otp_for("other-alerts@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "other-alerts@example.com",
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


def test_create_alert_returns_201_with_decimal_string_id(client, auth_headers):
    response = client.post(
        "/api/v1/alerts",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "condition": "ABOVE",
            "target": "190.000000",
        },
    )
    assert response.status_code == 201
    body = response.get_json()
    _assert_envelope(body)
    assert body["success"] is True
    assert isinstance(body["data"]["alertId"], str)
    assert body["data"]["alertId"].isdigit()
    assert body["data"]["symbol"] == "AAPL"


def test_create_alert_idempotency_key_returns_same_alert(client, auth_headers):
    headers = {**auth_headers, "Idempotency-Key": "alert-create-1"}
    payload = {
        "symbol": "MSFT",
        "condition": "BELOW",
        "target": "300.000000",
    }

    first = client.post("/api/v1/alerts", headers=headers, json=payload)
    second = client.post("/api/v1/alerts", headers=headers, json=payload)

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.get_json()["data"]["alertId"] == second.get_json()["data"]["alertId"]

    listed = client.get("/api/v1/alerts", headers=auth_headers)
    assert len(listed.get_json()["data"]["items"]) == 1


def test_update_alert_changes_target(client, auth_headers):
    create = client.post(
        "/api/v1/alerts",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "condition": "ABOVE",
            "target": "190.000000",
        },
    )
    alert_id = create.get_json()["data"]["alertId"]

    response = client.put(
        f"/api/v1/alerts/{alert_id}",
        headers=auth_headers,
        json={"target": "200.000000"},
    )
    assert response.status_code == 200
    assert response.get_json()["data"]["target"] == "200.000000"


def test_delete_alert_returns_204(client, auth_headers):
    create = client.post(
        "/api/v1/alerts",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "condition": "ABOVE",
            "target": "190.000000",
        },
    )
    alert_id = create.get_json()["data"]["alertId"]

    response = client.delete(f"/api/v1/alerts/{alert_id}", headers=auth_headers)
    assert response.status_code == 204

    listed = client.get("/api/v1/alerts", headers=auth_headers)
    assert listed.get_json()["data"]["items"] == []


def test_delete_other_users_alert_returns_404(
    client, auth_headers, other_auth_headers
):
    create = client.post(
        "/api/v1/alerts",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "condition": "ABOVE",
            "target": "190.000000",
        },
    )
    alert_id = create.get_json()["data"]["alertId"]

    response = client.delete(
        f"/api/v1/alerts/{alert_id}",
        headers=other_auth_headers,
    )
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "NOT_FOUND"


def test_list_alerts_pagination_includes_next_cursor(client, auth_headers):
    for symbol in ("AAPL", "MSFT", "GOOG"):
        client.post(
            "/api/v1/alerts",
            headers=auth_headers,
            json={
                "symbol": symbol,
                "condition": "ABOVE",
                "target": "100.000000",
            },
        )

    response = client.get("/api/v1/alerts?limit=2", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    _assert_envelope(body)
    assert len(body["data"]["items"]) == 2
    assert body["meta"]["nextCursor"] is not None


def test_alert_history_returns_trigger_events(client, auth_headers):
    create = client.post(
        "/api/v1/alerts",
        headers=auth_headers,
        json={
            "symbol": "AAPL",
            "condition": "ABOVE",
            "target": "190.000000",
        },
    )
    alert_id = int(create.get_json()["data"]["alertId"])
    user_id = int(create.get_json()["data"]["userId"])

    alert = AlertsService._get_owned_alert(user_id, alert_id)
    AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )

    response = client.get("/api/v1/alerts/history", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    assert len(body["data"]["items"]) == 1
    assert body["data"]["items"][0]["symbol"] == "AAPL"
    assert body["data"]["items"][0]["alertId"] == str(alert_id)


def test_alert_list_contract_shape(client, auth_headers):
    for payload in (
        {"symbol": "AAPL", "condition": "ABOVE", "target": "190.000000"},
        {"symbol": "MSFT", "condition": "BELOW", "target": "300.000000"},
    ):
        client.post("/api/v1/alerts", headers=auth_headers, json=payload)

    response = client.get("/api/v1/alerts?limit=2", headers=auth_headers)
    body = response.get_json()
    fixture = json.loads((CONTRACTS_DIR / "alert_list.json").read_text())

    for key in fixture["data"]:
        assert key in body["data"]
    for key in fixture["meta"]:
        assert key in body["meta"]
    for key in fixture["data"]["items"][0]:
        assert key in body["data"]["items"][0]
