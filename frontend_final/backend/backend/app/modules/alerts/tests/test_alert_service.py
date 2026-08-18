from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from sqlalchemy import func, select

from app.modules.alerts.models import Alert, AlertTriggerEvent
from app.modules.alerts.service import AlertEvaluationService, AlertsService
from app.modules.notifications.models import Notification, OutboxEvent
from app.shared.db import db


@pytest.fixture
def user_id(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "alert-service@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("alert-service@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "alert-service@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    return int(verify.get_json()["data"]["user"]["userId"])


def _create_alert(user_id: int, **kwargs) -> Alert:
    defaults = {
        "symbol": "AAPL",
        "condition": "ABOVE",
        "target": Decimal("190.000000"),
        "cooldown_seconds": 0,
    }
    defaults.update(kwargs)
    return AlertsService.create_alert(user_id, **defaults)


def test_above_triggers_when_price_crosses_target(user_id):
    alert = _create_alert(user_id, condition="ABOVE", target=Decimal("190.000000"))

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )

    assert triggered is True
    assert alert.triggered is True
    assert db.session.scalar(
        select(Notification).where(Notification.alert_id == alert.alert_id)
    ) is not None


def test_above_does_not_trigger_when_already_above_target(user_id):
    alert = _create_alert(user_id, condition="ABOVE", target=Decimal("190.000000"))

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("192.000000"),
        previous_price=Decimal("191.000000"),
    )

    assert triggered is False
    assert alert.triggered is False


def test_below_triggers_when_price_crosses_target(user_id):
    alert = _create_alert(user_id, condition="BELOW", target=Decimal("180.000000"))

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("179.000000"),
        previous_price=Decimal("181.000000"),
    )

    assert triggered is True
    assert alert.triggered is True


def test_percent_change_triggers_when_change_meets_target(user_id):
    alert = _create_alert(
        user_id,
        condition="PERCENT_CHANGE",
        target=Decimal("5.000000"),
    )

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("105.000000"),
        previous_price=Decimal("100.000000"),
    )

    assert triggered is True


def test_percent_change_does_not_trigger_when_change_below_target(user_id):
    alert = _create_alert(
        user_id,
        condition="PERCENT_CHANGE",
        target=Decimal("5.000000"),
    )

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("103.000000"),
        previous_price=Decimal("100.000000"),
    )

    assert triggered is False


def test_cooldown_active_prevents_trigger(user_id):
    alert = _create_alert(
        user_id,
        condition="ABOVE",
        target=Decimal("190.000000"),
        cooldown_seconds=300,
    )
    now = datetime.now(timezone.utc)
    alert.last_triggered_at = now - timedelta(seconds=60)
    db.session.commit()
    db.session.refresh(alert)

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )

    assert triggered is False


def test_cooldown_expired_allows_trigger(user_id):
    alert = _create_alert(
        user_id,
        condition="ABOVE",
        target=Decimal("190.000000"),
        cooldown_seconds=60,
    )
    alert.last_triggered_at = datetime.now(timezone.utc) - timedelta(seconds=120)
    alert.triggered = False
    db.session.commit()
    db.session.refresh(alert)

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )

    assert triggered is True


def test_duplicate_trigger_in_same_window_is_skipped(user_id):
    alert = _create_alert(user_id, condition="ABOVE", target=Decimal("190.000000"))

    first = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )
    assert first is True

    alert.triggered = False
    db.session.commit()
    db.session.refresh(alert)

    second = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("192.000000"),
        previous_price=Decimal("191.000000"),
    )

    assert second is False
    event_count = db.session.scalar(
        select(func.count())
        .select_from(AlertTriggerEvent)
        .where(AlertTriggerEvent.alert_id == alert.alert_id)
    )
    assert event_count == 1


def test_rearm_after_edit_allows_trigger_again(user_id):
    alert = _create_alert(user_id, condition="ABOVE", target=Decimal("190.000000"))

    AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("191.000000"),
        previous_price=Decimal("189.000000"),
    )

    AlertsService.update_alert(
        user_id,
        alert.alert_id,
        {"target": Decimal("195.000000"), "is_active": True},
    )
    db.session.refresh(alert)

    triggered = AlertEvaluationService.evaluate_alert_for_test(
        alert,
        current_price=Decimal("196.000000"),
        previous_price=Decimal("194.000000"),
    )

    assert triggered is True
    outbox_count = db.session.scalar(
        select(func.count())
        .select_from(OutboxEvent)
        .where(OutboxEvent.event_type == "alert_triggered")
    )
    assert outbox_count == 2
