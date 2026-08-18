from __future__ import annotations

from flask import Blueprint, g, request

from app.modules.notifications.service import NotificationService
from app.shared.auth import require_auth
from app.shared.pagination import parse_pagination_params
from app.shared.response import json_response

notifications_bp = Blueprint(
    "notifications", __name__, url_prefix="/api/v1/notifications"
)


def _user_id() -> int:
    return int(g.user_id)


@notifications_bp.get("")
@require_auth
def list_notifications():
    limit, cursor = parse_pagination_params(
        raw_limit=request.args.get("limit"),
        raw_cursor=request.args.get("cursor"),
    )
    data, meta = NotificationService.list_notifications(
        _user_id(), limit=limit, cursor=cursor
    )
    return json_response(data, meta=meta)


@notifications_bp.put("/read-all")
@require_auth
def mark_all_notifications_read():
    updated_count = NotificationService.mark_all_read(_user_id())
    return json_response({"updatedCount": updated_count})


@notifications_bp.put("/<int:notification_id>/read")
@require_auth
def mark_notification_read(notification_id: int):
    notification = NotificationService.mark_read(_user_id(), notification_id)
    return json_response(NotificationService.notification_to_dict(notification))
