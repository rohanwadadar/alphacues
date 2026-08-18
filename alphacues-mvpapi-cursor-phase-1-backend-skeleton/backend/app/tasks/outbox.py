"""Celery tasks for outbox event delivery."""

from __future__ import annotations

from app.extensions import celery


@celery.task(name="process_outbox_events")
def process_outbox_events() -> int:
    from app.modules.notifications.service import NotificationService

    return NotificationService.process_pending_outbox_events()
