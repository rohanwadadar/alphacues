from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from sqlalchemy import and_, delete, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.modules.alerts.models import (
    ALERT_CONDITIONS,
    Alert,
    AlertHistoryEvent,
    AlertTriggerEvent,
)
from app.modules.notifications.models import Notification, OutboxEvent
from app.shared.cache import CacheService
from app.shared.db import db
from app.shared.exceptions import NotFoundError
from app.shared.pagination import (
    decode_cursor,
    encode_cursor,
    paginate_rows,
    paginated_envelope,
)
from app.shared.validators import validate_symbol_input

IDEMPOTENCY_TTL_SECONDS = 86400


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _format_timestamp(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _cursor_sort_value(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _format_target(value: Decimal) -> str:
    return f"{value:.6f}"


def _idempotency_cache_key(user_id: int, idempotency_key: str) -> str:
    return f"idempotency:alert:{user_id}:{idempotency_key}"


class AlertsService:
    @staticmethod
    def _get_owned_alert(user_id: int, alert_id: int) -> Alert:
        alert = db.session.scalar(
            select(Alert).where(
                Alert.alert_id == alert_id,
                Alert.user_id == user_id,
            )
        )
        if alert is None:
            raise NotFoundError(message="Alert was not found.")
        return alert

    @staticmethod
    def alert_to_dict(alert: Alert) -> dict[str, Any]:
        return {
            "alertId": str(alert.alert_id),
            "userId": str(alert.user_id),
            "symbol": alert.symbol,
            "condition": alert.condition,
            "target": _format_target(alert.target),
            "isActive": alert.is_active,
            "triggered": alert.triggered,
            "cooldownSeconds": alert.cooldown_seconds,
            "lastTriggeredAt": (
                _format_timestamp(alert.last_triggered_at)
                if alert.last_triggered_at is not None
                else None
            ),
            "createdAt": _format_timestamp(alert.created_at),
        }

    @staticmethod
    def trigger_event_to_dict(event: AlertTriggerEvent, alert: Alert) -> dict[str, Any]:
        return {
            "id": str(event.id),
            "alertId": str(event.alert_id),
            "userId": str(alert.user_id),
            "symbol": alert.symbol,
            "condition": alert.condition,
            "target": _format_target(event.trigger_price or alert.target),
            "triggerPrice": _format_target(event.trigger_price or alert.target),
            "action": "TRIGGERED",
            "actionLabel": "Triggered",
            "isActive": False,
            "triggered": True,
            "cooldownSeconds": alert.cooldown_seconds or 0,
            "triggeredAt": _format_timestamp(event.triggered_at),
            "lastTriggeredAt": _format_timestamp(event.triggered_at),
            "createdAt": _format_timestamp(event.triggered_at or alert.created_at),
        }

    @staticmethod
    def history_event_to_dict(event: AlertHistoryEvent) -> dict[str, Any]:
        return {
            "id": str(event.id),
            "alertId": str(event.alert_id) if event.alert_id is not None else "",
            "userId": str(event.user_id),
            "symbol": event.symbol,
            "condition": event.condition,
            "target": _format_target(event.target),
            "triggerPrice": (
                _format_target(event.trigger_price)
                if event.trigger_price is not None
                else None
            ),
            "action": event.action,
            "actionLabel": event.action_label,
            "isActive": event.action == "CREATED",
            "triggered": event.action == "TRIGGERED",
            "cooldownSeconds": 0,
            "triggeredAt": (
                _format_timestamp(event.created_at)
                if event.action == "TRIGGERED"
                else None
            ),
            "lastTriggeredAt": (
                _format_timestamp(event.created_at)
                if event.action == "TRIGGERED"
                else None
            ),
            "createdAt": _format_timestamp(event.created_at),
        }

    @staticmethod
    def create_alert(
        user_id: int,
        *,
        symbol: str,
        condition: str,
        target: Decimal,
        cooldown_seconds: int = 0,
        idempotency_key: str | None = None,
    ) -> Alert:
        if condition not in ALERT_CONDITIONS:
            raise ValueError(f"Invalid condition: {condition}")

        normalized_symbol = validate_symbol_input(symbol)

        if idempotency_key:
            cache = CacheService()
            cache_key = _idempotency_cache_key(user_id, idempotency_key)
            cached_alert_id = cache.get(cache_key)
            if cached_alert_id is not None:
                existing = db.session.scalar(
                    select(Alert).where(
                        Alert.alert_id == int(cached_alert_id),
                        Alert.user_id == user_id,
                    )
                )
                if existing is not None:
                    return existing

        next_id = (db.session.scalar(select(func.max(Alert.alert_id))) or 0) + 1
        alert = Alert(
            alert_id=next_id,
            user_id=user_id,
            symbol=normalized_symbol,
            condition=condition,
            target=target,
            cooldown_seconds=cooldown_seconds,
        )
        db.session.add(alert)

        history_event = AlertHistoryEvent(
            alert_id=alert.alert_id,
            user_id=user_id,
            symbol=normalized_symbol,
            condition=condition,
            target=target,
            trigger_price=None,
            action="CREATED",
            action_label="Set",
            created_at=alert.created_at,
        )
        db.session.add(history_event)
        db.session.commit()

        if idempotency_key:
            CacheService().set(
                _idempotency_cache_key(user_id, idempotency_key),
                str(alert.alert_id),
                ttl_seconds=IDEMPOTENCY_TTL_SECONDS,
            )

        try:
            curr_price = None
            cached_quote = CacheService().get_json(f"market:quote:{normalized_symbol}")
            if cached_quote and "lastPrice" in cached_quote:
                curr_price = Decimal(str(cached_quote["lastPrice"]))
            else:
                from flask import current_app
                adapter = current_app.extensions.get("market_data_adapter") if current_app else None
                if adapter:
                    q = adapter.get_quote(normalized_symbol)
                    if q and q.lastPrice > 0:
                        curr_price = q.lastPrice

            if curr_price is not None:
                if AlertEvaluationService.evaluate_alert(alert, curr_price, None):
                    from app.modules.notifications.service import NotificationService
                    NotificationService.process_pending_outbox_events()
        except Exception:
            pass

        return alert

    @staticmethod
    def update_alert(user_id: int, alert_id: int, updates: dict[str, Any]) -> Alert:
        alert = AlertsService._get_owned_alert(user_id, alert_id)

        if "symbol" in updates:
            alert.symbol = validate_symbol_input(updates["symbol"])
        if "condition" in updates:
            alert.condition = updates["condition"]
        if "target" in updates:
            alert.target = updates["target"]
        if "cooldown_seconds" in updates:
            alert.cooldown_seconds = updates["cooldown_seconds"]
        if "is_active" in updates:
            alert.is_active = updates["is_active"]

        edited = any(
            key in updates for key in ("symbol", "condition", "target", "is_active")
        )
        if edited:
            history_event = AlertHistoryEvent(
                alert_id=alert.alert_id,
                user_id=user_id,
                symbol=alert.symbol,
                condition=alert.condition,
                target=alert.target,
                trigger_price=None,
                action="UPDATED",
                action_label="Updated",
                created_at=_utcnow(),
            )
            db.session.add(history_event)

        if edited and alert.is_active:
            alert.triggered = False
            alert.last_triggered_at = None
            db.session.execute(
                delete(AlertTriggerEvent).where(
                    AlertTriggerEvent.alert_id == alert.alert_id
                )
            )

        db.session.commit()
        return alert

    @staticmethod
    def delete_alert(user_id: int, alert_id: int) -> None:
        alert = AlertsService._get_owned_alert(user_id, alert_id)
        history_event = AlertHistoryEvent(
            alert_id=alert.alert_id,
            user_id=user_id,
            symbol=alert.symbol,
            condition=alert.condition,
            target=alert.target,
            trigger_price=None,
            action="DELETED",
            action_label="Removed",
            created_at=_utcnow(),
        )
        db.session.add(history_event)
        db.session.execute(
            delete(AlertTriggerEvent).where(
                AlertTriggerEvent.alert_id == alert.alert_id
            )
        )
        db.session.delete(alert)
        db.session.commit()

    @staticmethod
    def list_alerts(
        user_id: int,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        query = (
            select(Alert)
            .where(Alert.user_id == user_id)
            .order_by(Alert.created_at.desc(), Alert.alert_id.desc())
        )

        if cursor is not None:
            sort_value, row_id = decode_cursor(cursor)
            cursor_created_at = datetime.fromisoformat(
                sort_value.replace("Z", "+00:00")
            )
            query = query.where(
                or_(
                    Alert.created_at < cursor_created_at,
                    and_(
                        Alert.created_at == cursor_created_at,
                        Alert.alert_id < row_id,
                    ),
                )
            )

        rows = list(db.session.scalars(query.limit(limit + 1)).all())
        page, next_cursor = paginate_rows(
            rows,
            limit=limit,
            cursor_extractor=lambda alert: (
                _cursor_sort_value(alert.created_at),
                alert.alert_id,
            ),
        )
        items = [AlertsService.alert_to_dict(alert) for alert in page]
        return paginated_envelope(items, next_cursor=next_cursor)

    @staticmethod
    def ensure_history_migrated() -> None:
        try:
            # Check if alert_history_events has any rows
            count = db.session.scalar(select(func.count(AlertHistoryEvent.id)))
            if count == 0:
                # 1. Backfill existing alerts as "CREATED" / "Set"
                existing_alerts = db.session.scalars(select(Alert)).all()
                for a in existing_alerts:
                    db.session.add(
                        AlertHistoryEvent(
                            alert_id=a.alert_id,
                            user_id=a.user_id,
                            symbol=a.symbol,
                            condition=a.condition,
                            target=a.target,
                            trigger_price=None,
                            action="CREATED",
                            action_label="Set",
                            created_at=a.created_at,
                        )
                    )
                # 2. Backfill existing trigger events as "TRIGGERED"
                existing_triggers = db.session.execute(
                    select(
                        AlertTriggerEvent,
                        Alert.user_id,
                        Alert.symbol,
                        Alert.condition,
                        Alert.target,
                    ).outerjoin(Alert, Alert.alert_id == AlertTriggerEvent.alert_id)
                ).all()
                for trig, u_id, sym, cond, tgt in existing_triggers:
                    if u_id:
                        db.session.add(
                            AlertHistoryEvent(
                                alert_id=trig.alert_id,
                                user_id=u_id,
                                symbol=sym or "UNKNOWN",
                                condition=cond or "ABOVE",
                                target=tgt or trig.trigger_price,
                                trigger_price=trig.trigger_price,
                                action="TRIGGERED",
                                action_label="Triggered",
                                created_at=trig.triggered_at,
                            )
                        )
                db.session.commit()
        except Exception:
            db.session.rollback()

    @staticmethod
    def _list_legacy_trigger_history(
        user_id: int,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        query = (
            select(AlertTriggerEvent, Alert)
            .join(Alert, Alert.alert_id == AlertTriggerEvent.alert_id)
            .where(Alert.user_id == user_id)
            .order_by(
                AlertTriggerEvent.triggered_at.desc(),
                AlertTriggerEvent.id.desc(),
            )
        )

        if cursor is not None:
            sort_value, row_id = decode_cursor(cursor)
            cursor_triggered_at = datetime.fromisoformat(
                sort_value.replace("Z", "+00:00")
            )
            query = query.where(
                or_(
                    AlertTriggerEvent.triggered_at < cursor_triggered_at,
                    and_(
                        AlertTriggerEvent.triggered_at == cursor_triggered_at,
                        AlertTriggerEvent.id < row_id,
                    ),
                )
            )

        rows = list(db.session.execute(query.limit(limit + 1)).all())
        page, next_cursor = paginate_rows(
            rows,
            limit=limit,
            cursor_extractor=lambda row: (
                _cursor_sort_value(row[0].triggered_at),
                row[0].id,
            ),
        )
        items = [
            AlertsService.trigger_event_to_dict(event, alert)
            for event, alert in page
        ]
        return paginated_envelope(items, next_cursor=next_cursor)

    @staticmethod
    def list_trigger_history(
        user_id: int,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        AlertsService.ensure_history_migrated()

        query = (
            select(AlertHistoryEvent)
            .where(AlertHistoryEvent.user_id == user_id)
            .order_by(
                AlertHistoryEvent.created_at.desc(),
                AlertHistoryEvent.id.desc(),
            )
        )

        if cursor is not None:
            sort_value, row_id = decode_cursor(cursor)
            cursor_created_at = datetime.fromisoformat(
                sort_value.replace("Z", "+00:00")
            )
            query = query.where(
                or_(
                    AlertHistoryEvent.created_at < cursor_created_at,
                    and_(
                        AlertHistoryEvent.created_at == cursor_created_at,
                        AlertHistoryEvent.id < row_id,
                    ),
                )
            )

        rows = list(db.session.scalars(query.limit(limit + 1)).all())
        if not rows and cursor is None:
            return AlertsService._list_legacy_trigger_history(
                user_id, limit=limit, cursor=cursor
            )

        page, next_cursor = paginate_rows(
            rows,
            limit=limit,
            cursor_extractor=lambda event: (
                _cursor_sort_value(event.created_at),
                event.id,
            ),
        )
        items = [
            AlertsService.history_event_to_dict(event)
            for event in page
        ]
        return paginated_envelope(items, next_cursor=next_cursor)


class AlertEvaluationService:
    @staticmethod
    def _direction_label(condition: str) -> str:
        if condition == "ABOVE":
            return "above"
        if condition == "BELOW":
            return "below"
        return "changed by"

    @staticmethod
    def _should_trigger_condition(
        alert: Alert,
        current_price: Decimal,
        previous_price: Decimal | None,
    ) -> bool:
        target = alert.target
        if alert.condition == "ABOVE":
            if current_price <= target:
                return False
            if previous_price is None:
                return True
            return previous_price <= target
        if alert.condition == "BELOW":
            if current_price >= target:
                return False
            if previous_price is None:
                return True
            return previous_price >= target
        if alert.condition == "PERCENT_CHANGE":
            if previous_price is None or previous_price == 0:
                return False
            change_pct = abs((current_price - previous_price) / previous_price * 100)
            return change_pct >= target
        return False

    @staticmethod
    def _cooldown_active(alert: Alert, now: datetime) -> bool:
        if alert.last_triggered_at is None or alert.cooldown_seconds <= 0:
            return False
        elapsed = (now - alert.last_triggered_at).total_seconds()
        return elapsed < alert.cooldown_seconds

    @staticmethod
    def _has_trigger_in_current_window(
        session: Session,
        alert_id: int,
        now: datetime,
    ) -> bool:
        from datetime import timedelta
        start_of_minute = now.replace(second=0, microsecond=0)
        end_of_minute = start_of_minute + timedelta(minutes=1)
        query = (
            select(AlertTriggerEvent.id)
            .where(
                AlertTriggerEvent.alert_id == alert_id,
                AlertTriggerEvent.triggered_at >= start_of_minute,
                AlertTriggerEvent.triggered_at < end_of_minute,
            )
        )
        bind = session.get_bind()
        if bind is not None and bind.dialect.name != "sqlite":
            query = query.with_for_update()
        existing = session.scalar(query)
        return existing is not None

    @staticmethod
    def evaluate_alert(
        alert: Alert,
        current_price: Decimal,
        previous_price: Decimal | None,
        *,
        session: Session | None = None,
    ) -> bool:
        """Return True when an alert trigger transaction was committed."""
        if not alert.is_active:
            return False

        now = _utcnow()

        if AlertEvaluationService._cooldown_active(alert, now):
            return False

        if not AlertEvaluationService._should_trigger_condition(
            alert, current_price, previous_price
        ):
            return False

        db_session = session or db.session
        owns_transaction = session is None

        if AlertEvaluationService._has_trigger_in_current_window(
            db_session, alert.alert_id, now
        ):
            return False

        direction = AlertEvaluationService._direction_label(alert.condition)
        title_target = f"{alert.target:.2f}"
        title = f"{alert.symbol} crossed {direction} {title_target}"
        body = f"Your {alert.symbol} {alert.condition} alert was triggered."

        trigger_event = AlertTriggerEvent(
            alert_id=alert.alert_id,
            triggered_at=now,
            trigger_price=current_price,
        )
        db_session.add(trigger_event)

        history_event = AlertHistoryEvent(
            alert_id=alert.alert_id,
            user_id=alert.user_id,
            symbol=alert.symbol,
            condition=alert.condition,
            target=alert.target,
            trigger_price=current_price,
            action="TRIGGERED",
            action_label="Triggered",
            created_at=now,
        )
        db_session.add(history_event)

        alert.triggered = True
        alert.last_triggered_at = now

        notification = Notification(
            user_id=alert.user_id,
            alert_id=alert.alert_id,
            title=title,
            body=body,
        )
        db_session.add(notification)
        db_session.flush()

        outbox = OutboxEvent(
            event_type="alert_triggered",
            payload={
                "notificationId": str(notification.notification_id),
                "alertId": str(alert.alert_id),
                "userId": str(alert.user_id),
                "channel": "IN_APP",
                "title": title,
                "body": body,
                "createdAt": _format_timestamp(now),
            },
            status="pending",
            next_attempt_at=now,
        )
        db_session.add(outbox)

        try:
            if owns_transaction:
                db_session.commit()
            else:
                db_session.flush()
        except IntegrityError:
            if owns_transaction:
                db_session.rollback()
            return False

        return True
 
    @staticmethod
    def evaluate_alerts_for_symbol(
        symbol: str,
        current_price: Decimal,
        previous_price: Decimal | None = None,
    ) -> int:
        """Find active, untriggered alerts for symbol and evaluate them."""
        normalized = symbol.upper().strip()
        active_alerts = list(
            db.session.scalars(
                select(Alert).where(
                    Alert.symbol == normalized,
                    Alert.is_active == True,
                    Alert.triggered == False,
                )
            ).all()
        )
        if not active_alerts:
            return 0

        triggered_count = 0
        for alert in active_alerts:
            try:
                if AlertEvaluationService.evaluate_alert(
                    alert, current_price, previous_price
                ):
                    triggered_count += 1
            except Exception:
                db.session.rollback()

        if triggered_count > 0:
            try:
                from app.modules.notifications.service import NotificationService
                NotificationService.process_pending_outbox_events()
            except Exception:
                pass

        return triggered_count

    @staticmethod
    def evaluate_all_active_alerts() -> int:
        """Scan and evaluate all active, untriggered alerts against latest prices."""
        active_alerts = list(
            db.session.scalars(
                select(Alert).where(
                    Alert.is_active == True,
                    Alert.triggered == False,
                )
            ).all()
        )
        if not active_alerts:
            return 0

        symbols = {a.symbol for a in active_alerts}
        from app.shared.cache import CacheService
        cache = CacheService()

        total_triggered = 0
        from flask import current_app
        adapter = current_app.extensions.get("market_data_adapter") if current_app else None

        for sym in symbols:
            try:
                price = None
                cached_quote = cache.get_json(f"market:quote:{sym}")
                if cached_quote and "lastPrice" in cached_quote:
                    price = Decimal(str(cached_quote["lastPrice"]))
                elif adapter:
                    q = adapter.get_quote(sym)
                    if q and q.lastPrice > 0:
                        price = q.lastPrice
                
                if price is not None and price > 0:
                    total_triggered += AlertEvaluationService.evaluate_alerts_for_symbol(sym, price)
            except Exception:
                pass

        return total_triggered

    @staticmethod
    def evaluate_alert_for_test(
        alert: Alert,
        current_price: Decimal,
        previous_price: Decimal | None,
    ) -> bool:
        """Test helper that refreshes alert state after evaluation."""
        result = AlertEvaluationService.evaluate_alert(
            alert, current_price, previous_price
        )
        if result:
            db.session.refresh(alert)
        return result
