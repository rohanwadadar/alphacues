from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from marshmallow import Schema, fields, validate, validates

from app.modules.portfolio.models import PORTFOLIO_ACTIONS


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class PortfolioEventSchema(Schema):
    symbol = fields.String(required=True)
    action = fields.String(
        required=True,
        validate=validate.OneOf(list(PORTFOLIO_ACTIONS)),
    )
    price = fields.Decimal(
        required=True,
        places=6,
        as_string=False,
        validate=validate.Range(min=Decimal("0.000001")),
    )
    volume = fields.Integer(
        required=True,
        validate=validate.Range(min=1),
    )
    time_stamp = fields.DateTime(
        required=False,
        load_default=_utcnow,
    )

    @validates("symbol")
    def validate_symbol_field(self, value: str) -> None:
        from app.shared.validators import validate_symbol_input

        validate_symbol_input(value)


class PortfolioEventUpdateSchema(Schema):
    symbol = fields.String(required=True)
    action = fields.String(
        required=True,
        validate=validate.OneOf(list(PORTFOLIO_ACTIONS)),
    )
    price = fields.Decimal(
        required=True,
        places=6,
        as_string=False,
        validate=validate.Range(min=Decimal("0.000001")),
    )
    volume = fields.Integer(
        required=True,
        validate=validate.Range(min=1),
    )
    time_stamp = fields.DateTime(required=False)

    @validates("symbol")
    def validate_symbol_field(self, value: str) -> None:
        from app.shared.validators import validate_symbol_input

        validate_symbol_input(value)
