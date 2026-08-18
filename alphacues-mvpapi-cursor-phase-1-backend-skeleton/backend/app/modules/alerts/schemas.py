from __future__ import annotations

from decimal import Decimal

from marshmallow import Schema, ValidationError, fields, validate, validates, validates_schema

from app.modules.alerts.models import ALERT_CONDITIONS


class AlertCreateSchema(Schema):
    symbol = fields.String(required=True)
    condition = fields.String(
        required=True,
        validate=validate.OneOf(list(ALERT_CONDITIONS)),
    )
    target = fields.Decimal(
        required=True,
        places=6,
        as_string=False,
        validate=validate.Range(min=Decimal("0.000001")),
    )
    cooldown_seconds = fields.Integer(
        load_default=0,
        validate=validate.Range(min=0),
    )

    @validates("symbol")
    def validate_symbol_field(self, value: str) -> None:
        from app.shared.validators import validate_symbol_input

        validate_symbol_input(value)


class AlertUpdateSchema(Schema):
    symbol = fields.String(required=False)
    condition = fields.String(
        required=False,
        validate=validate.OneOf(list(ALERT_CONDITIONS)),
    )
    target = fields.Decimal(
        required=False,
        places=6,
        as_string=False,
        validate=validate.Range(min=Decimal("0.000001")),
    )
    is_active = fields.Boolean(required=False)
    cooldown_seconds = fields.Integer(
        required=False,
        validate=validate.Range(min=0),
    )

    @validates("symbol")
    def validate_symbol_field(self, value: str) -> None:
        from app.shared.validators import validate_symbol_input

        validate_symbol_input(value)

    @validates_schema
    def validate_at_least_one_field(self, data: dict, **kwargs) -> None:
        if not data:
            raise ValidationError("At least one field must be provided.")


class AlertResponseSchema(Schema):
    alertId = fields.String(required=True)
    userId = fields.String(required=True)
    symbol = fields.String(required=True)
    condition = fields.String(required=True)
    target = fields.Decimal(required=True, places=6, as_string=True)
    isActive = fields.Boolean(required=True)
    triggered = fields.Boolean(required=True)
    cooldownSeconds = fields.Integer(required=True)
    lastTriggeredAt = fields.String(required=False, allow_none=True)
    createdAt = fields.String(required=True)


class AlertTriggerEventResponseSchema(Schema):
    id = fields.String(required=True)
    alertId = fields.String(required=True)
    symbol = fields.String(required=True)
    condition = fields.String(required=True)
    triggerPrice = fields.Decimal(required=True, places=6, as_string=True)
    triggeredAt = fields.String(required=True)
