from __future__ import annotations

import json
from decimal import Decimal
from pathlib import Path
from urllib.parse import quote

import pytest

from app.modules.alerts.service import AlertEvaluationService, AlertsService

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "notifications-routes@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("notifications-routes@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "notifications-routes@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    access_token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {access_token}"}


def _create_notification_via_alert(client, auth_headers):
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


def test_list_notifications_paginated_with_next_cursor(client, auth_headers):
    for _ in range(3):
        _create_notification_via_alert(client, auth_headers)

    response = client.get("/api/v1/notifications?limit=2", headers=auth_headers)
    assert response.status_code == 200
    body = response.get_json()
    assert len(body["data"]["items"]) == 2
    assert body["meta"]["nextCursor"] is not None


def test_list_notifications_page_two_with_cursor(client, auth_headers):
    for _ in range(3):
        _create_notification_via_alert(client, auth_headers)

    page_one = client.get("/api/v1/notifications?limit=2", headers=auth_headers)
    cursor = page_one.get_json()["meta"]["nextCursor"]
    first_ids = {item["notificationId"] for item in page_one.get_json()["data"]["items"]}

    page_two = client.get(
        f"/api/v1/notifications?limit=2&cursor={quote(cursor, safe='')}",
        headers=auth_headers,
    )
    second_ids = {item["notificationId"] for item in page_two.get_json()["data"]["items"]}

    assert first_ids.isdisjoint(second_ids)
    assert len(page_two.get_json()["data"]["items"]) == 1


def test_mark_notification_read(client, auth_headers):
    _create_notification_via_alert(client, auth_headers)

    listed = client.get("/api/v1/notifications", headers=auth_headers)
    notification_id = listed.get_json()["data"]["items"][0]["notificationId"]
    assert listed.get_json()["data"]["items"][0]["isRead"] is False

    response = client.put(
        f"/api/v1/notifications/{notification_id}/read",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.get_json()["data"]["isRead"] is True


def test_mark_all_notifications_read(client, auth_headers):
    for _ in range(2):
        _create_notification_via_alert(client, auth_headers)

    response = client.put("/api/v1/notifications/read-all", headers=auth_headers)
    assert response.status_code == 200
    assert response.get_json()["data"]["updatedCount"] == 2

    listed = client.get("/api/v1/notifications", headers=auth_headers)
    assert all(item["isRead"] for item in listed.get_json()["data"]["items"])


def test_notification_list_contract_shape(client, auth_headers):
    for _ in range(2):
        _create_notification_via_alert(client, auth_headers)

    response = client.get("/api/v1/notifications?limit=2", headers=auth_headers)
    body = response.get_json()
    fixture = json.loads((CONTRACTS_DIR / "notification_list.json").read_text())

    for key in fixture["data"]:
        assert key in body["data"]
    for key in fixture["meta"]:
        assert key in body["meta"]
    for key in fixture["data"]["items"][0]:
        assert key in body["data"]["items"][0]
