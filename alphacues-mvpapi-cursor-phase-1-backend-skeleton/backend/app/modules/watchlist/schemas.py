from __future__ import annotations

from marshmallow import Schema, ValidationError, fields, validates


class CreateWatchlistSchema(Schema):
    name = fields.String(required=True, validate=fields.validate.Length(min=1, max=200))


class RenameWatchlistSchema(Schema):
    name = fields.String(required=True, validate=fields.validate.Length(min=1, max=200))


class AddWatchlistItemSchema(Schema):
    symbol = fields.String(required=True)
    quantity = fields.Float(required=False, allow_none=True)

    @validates("symbol")
    def validate_symbol_field(self, value: str) -> None:
        from app.shared.validators import validate_symbol_input

        validate_symbol_input(value)
