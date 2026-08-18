from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select, update

from app.modules.notifications.models import Notification, OutboxEvent
from app.shared.db import db
from app.shared.exceptions import NotFoundError
from app.shared.pagination import (
    decode_cursor,
    paginate_rows,
    paginated_envelope,
)


def _format_timestamp(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _cursor_sort_value(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


class NotificationService:
    @staticmethod
    def notification_to_dict(notification: Notification) -> dict[str, Any]:
        return {
            "notificationId": str(notification.notification_id),
            "userId": str(notification.user_id),
            "alertId": (
                str(notification.alert_id)
                if notification.alert_id is not None
                else None
            ),
            "title": notification.title,
            "body": notification.body,
            "isRead": notification.is_read,
            "createdAt": _format_timestamp(notification.created_at),
        }

    @staticmethod
    def _get_owned_notification(user_id: int, notification_id: int) -> Notification:
        notification = db.session.scalar(
            select(Notification).where(
                Notification.notification_id == notification_id,
                Notification.user_id == user_id,
            )
        )
        if notification is None:
            raise NotFoundError(message="Notification was not found.")
        return notification

    @staticmethod
    def list_notifications(
        user_id: int,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        from sqlalchemy import and_, or_

        query = (
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(
                Notification.created_at.desc(),
                Notification.notification_id.desc(),
            )
        )

        if cursor is not None:
            sort_value, row_id = decode_cursor(cursor)
            cursor_created_at = datetime.fromisoformat(
                sort_value.replace("Z", "+00:00")
            )
            query = query.where(
                or_(
                    Notification.created_at < cursor_created_at,
                    and_(
                        Notification.created_at == cursor_created_at,
                        Notification.notification_id < row_id,
                    ),
                )
            )

        rows = list(db.session.scalars(query.limit(limit + 1)).all())
        page, next_cursor = paginate_rows(
            rows,
            limit=limit,
            cursor_extractor=lambda notification: (
                _cursor_sort_value(notification.created_at),
                notification.notification_id,
            ),
        )
        items = [
            NotificationService.notification_to_dict(notification)
            for notification in page
        ]
        return paginated_envelope(items, next_cursor=next_cursor)

    @staticmethod
    def mark_read(user_id: int, notification_id: int) -> Notification:
        notification = NotificationService._get_owned_notification(
            user_id, notification_id
        )
        notification.is_read = True
        db.session.commit()
        return notification

    @staticmethod
    def mark_all_read(user_id: int) -> int:
        result = db.session.execute(
            update(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
            .values(is_read=True)
        )
        db.session.commit()
        return int(result.rowcount or 0)

    @staticmethod
    def process_pending_outbox_events(*, batch_size: int = 50, max_attempts: int = 3) -> int:
        from app.extensions import socketio
        from app.shared.websocket import STREAM_NAMESPACE, _user_room

        now = datetime.now(timezone.utc)
        events = list(
            db.session.scalars(
                select(OutboxEvent)
                .where(
                    OutboxEvent.status == "pending",
                    OutboxEvent.next_attempt_at <= now,
                )
                .order_by(OutboxEvent.id.asc())
                .limit(batch_size)
                .with_for_update(skip_locked=True)
            ).all()
        )

        processed = 0
        for event in events:
            if event.status != "pending":
                continue

            try:
                if event.event_type == "alert_triggered":
                    payload = event.payload
                    user_id = int(payload["userId"])
                    notification_payload = {
                        "notificationId": str(payload["notificationId"]),
                        "alertId": str(payload["alertId"]),
                        "title": payload["title"],
                        "body": payload["body"],
                        "createdAt": payload["createdAt"],
                    }
                    socketio.emit(
                        "notification_new",
                        notification_payload,
                        room=_user_room(str(user_id)),
                        namespace=STREAM_NAMESPACE,
                    )
                    socketio.emit(
                        "alert_triggered",
                        {
                            "alertId": str(payload["alertId"]),
                            "notificationId": str(payload["notificationId"]),
                        },
                        room=_user_room(str(user_id)),
                        namespace=STREAM_NAMESPACE,
                    )

                    # FCM Push logic
                    try:
                        from firebase_admin import messaging
                        from app.modules.notifications.service import DevicePushTokenService
                        
                        active_tokens = DevicePushTokenService.active_tokens_for(user_id)
                        if active_tokens:
                            message = messaging.MulticastMessage(
                                tokens=active_tokens,
                                notification=messaging.Notification(
                                    title=payload["title"],
                                    body=payload["body"],
                                ),
                                data={
                                    "deepLink": f"/alerts",
                                    "alertId": str(payload["alertId"]),
                                    "notificationId": str(payload["notificationId"]),
                                },
                            )
                            response = messaging.send_each_for_multicast(message)
                            if response.failure_count > 0:
                                invalid_tokens = []
                                for idx, resp in enumerate(response.responses):
                                    if not resp.success:
                                        if resp.exception and resp.exception.code in (
                                            "messaging/invalid-registration-token",
                                            "messaging/registration-token-not-registered",
                                        ):
                                            invalid_tokens.append(active_tokens[idx])
                                if invalid_tokens:
                                    DevicePushTokenService.remove_invalid_tokens(invalid_tokens)
                    except Exception as e:
                        import logging
                        logging.getLogger("fcm").error(f"FCM push failed: {e}")

                event.status = "delivered"
                processed += 1
            except Exception:
                current_payload = dict(event.payload or {})
                attempts = int(current_payload.get("_attempts", 0)) + 1
                current_payload["_attempts"] = attempts

                if attempts >= max_attempts:
                    event.status = "dead_letter"
                else:
                    event.status = "pending"
                    backoff_seconds = (2 ** (attempts - 1)) * 5
                    from datetime import timedelta
                    event.next_attempt_at = now + timedelta(seconds=backoff_seconds)
                event.payload = current_payload
            db.session.commit()

        return processed

    @staticmethod
    def get_dead_letter_events(*, limit: int = 50) -> list[dict[str, Any]]:
        """Query exhausted or failed outbox events for dead-letter visibility."""
        events = db.session.scalars(
            select(OutboxEvent)
            .where(OutboxEvent.status.in_(["dead_letter", "failed"]))
            .order_by(OutboxEvent.id.desc())
            .limit(limit)
        ).all()

        return [
            {
                "id": str(e.id),
                "eventType": e.event_type,
                "status": e.status,
                "payload": e.payload,
                "attempts": e.payload.get("_attempts", 0) if isinstance(e.payload, dict) else 0,
                "createdAt": e.created_at.isoformat() if e.created_at else None,
            }
            for e in events
        ]

    @staticmethod
    def get_outbox_metrics() -> dict[str, Any]:
        """Provides monitoring metrics for outbox queue depth, lag, and dead-letter count."""
        now = datetime.now(timezone.utc)
        pending_events = db.session.scalars(
            select(OutboxEvent).where(OutboxEvent.status == "pending")
        ).all()

        queue_depth = len(pending_events)
        max_lag_seconds = 0.0
        for ev in pending_events:
            if ev.next_attempt_at:
                next_att = ev.next_attempt_at
                if next_att.tzinfo is None:
                    next_att = next_att.replace(tzinfo=timezone.utc)
                lag = (now - next_att).total_seconds()
                if lag > max_lag_seconds:
                    max_lag_seconds = lag

        dead_letter_count = db.session.scalar(
            select(func.count(OutboxEvent.id)).where(OutboxEvent.status.in_(["dead_letter", "failed"]))
        ) or 0

        delivered_count = db.session.scalar(
            select(func.count(OutboxEvent.id)).where(OutboxEvent.status == "delivered")
        ) or 0

        return {
            "queueDepth": queue_depth,
            "processingLagSeconds": round(max_lag_seconds, 2),
            "deadLetterCount": int(dead_letter_count),
            "deliveredCount": int(delivered_count),
        }


class DevicePushTokenService:
    @staticmethod
    def register_token(
        user_id: int, device_id: str, fcm_token: str, platform: str, app_version: str | None = None
    ) -> DevicePushToken:
        from app.modules.user.models import DevicePushToken
        
        token = db.session.scalar(
            select(DevicePushToken).where(
                DevicePushToken.user_id == user_id,
                (DevicePushToken.device_id == device_id) | (DevicePushToken.fcm_token == fcm_token)
            )
        )

        if token:
            token.fcm_token = fcm_token
            token.platform = platform
            token.app_version = app_version
            token.last_seen_at = datetime.now(timezone.utc)
            token.is_active = True
        else:
            token = DevicePushToken(
                device_id=device_id,
                user_id=user_id,
                fcm_token=fcm_token,
                platform=platform,
                app_version=app_version,
            )
            db.session.add(token)
        db.session.commit()
        return token

    @staticmethod
    def unregister_token(user_id: int, device_id: str) -> None:
        from app.modules.user.models import DevicePushToken
        token = db.session.scalar(
            select(DevicePushToken).where(
                DevicePushToken.user_id == user_id,
                DevicePushToken.device_id == device_id
            )
        )
        if token:
            db.session.delete(token)
            db.session.commit()


    @staticmethod
    def update_preferences(user_id: int, device_id: str, is_active: bool) -> DevicePushToken:
        from app.modules.user.models import DevicePushToken
        token = db.session.scalar(
            select(DevicePushToken).where(
                DevicePushToken.user_id == user_id,
                DevicePushToken.device_id == device_id
            )
        )
        if not token:
            raise NotFoundError(message="Device not found.")
        token.is_active = is_active
        db.session.commit()
        return token

    @staticmethod
    def active_tokens_for(user_id: int) -> list[str]:
        from app.modules.user.models import DevicePushToken
        tokens = db.session.scalars(
            select(DevicePushToken.fcm_token).where(
                DevicePushToken.user_id == user_id,
                DevicePushToken.is_active == True
            )
        ).all()
        return list(tokens)

    @staticmethod
    def remove_invalid_tokens(fcm_tokens: list[str]) -> None:
        from app.modules.user.models import DevicePushToken
        if fcm_tokens:
            db.session.execute(
                select(DevicePushToken).where(DevicePushToken.fcm_token.in_(fcm_tokens))
            )
            tokens = db.session.scalars(
                select(DevicePushToken).where(DevicePushToken.fcm_token.in_(fcm_tokens))
            ).all()
            for t in tokens:
                db.session.delete(t)
            db.session.commit()
