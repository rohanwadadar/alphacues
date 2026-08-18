from __future__ import annotations

from marshmallow import Schema, fields


class NotificationResponseSchema(Schema):
    notificationId = fields.String(required=True)
    userId = fields.String(required=True)
    alertId = fields.String(required=False, allow_none=True)
    title = fields.String(required=True)
    body = fields.String(required=True)
    isRead = fields.Boolean(required=True)
    createdAt = fields.String(required=True)
