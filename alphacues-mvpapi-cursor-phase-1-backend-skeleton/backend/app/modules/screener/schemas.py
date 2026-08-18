from __future__ import annotations

from decimal import Decimal
from typing import Any

from marshmallow import (
    Schema,
    ValidationError,
    fields,
    post_load,
    validate,
    validates_schema,
)

VALID_SORT_FIELDS = ("marketCap", "peRatio", "price", "changePercent", "symbol")
VALID_SORT_ORDERS = ("asc", "desc")


class ScreenerFilterSchema(Schema):
    marketCapMin = fields.Decimal(required=False, allow_none=True, min=0)
    marketCapMax = fields.Decimal(required=False, allow_none=True, min=0)
    peRatioMin = fields.Decimal(required=False, allow_none=True, min=0)
    peRatioMax = fields.Decimal(required=False, allow_none=True, min=0)
    priceMin = fields.Decimal(required=False, allow_none=True, min=0)
    priceMax = fields.Decimal(required=False, allow_none=True, min=0)
    changePercentMin = fields.Decimal(required=False, allow_none=True)
    changePercentMax = fields.Decimal(required=False, allow_none=True)
    dividendYieldMin = fields.Decimal(required=False, allow_none=True, min=0)
    exchange = fields.String(required=False, allow_none=True)

    @validates_schema
    def validate_ranges(self, data: dict[str, Any], **kwargs: Any) -> None:
        def _check(min_key: str, max_key: str, label: str) -> None:
            min_val = data.get(min_key)
            max_val = data.get(max_key)
            if min_val is not None and max_val is not None and min_val > max_val:
                raise ValidationError(
                    f"{label} minimum cannot be greater than maximum.",
                    field_name=min_key,
                )

        _check("marketCapMin", "marketCapMax", "Market cap")
        _check("peRatioMin", "peRatioMax", "P/E ratio")
        _check("priceMin", "priceMax", "Price")
        _check("changePercentMin", "changePercentMax", "Change percent")


class ScreenerScanRequestSchema(Schema):
    filters = fields.Nested(ScreenerFilterSchema, load_default=dict)
    sort_by = fields.String(
        load_default="marketCap",
        validate=validate.OneOf(VALID_SORT_FIELDS),
    )
    sort_order = fields.String(
        load_default="desc",
        validate=validate.OneOf(VALID_SORT_ORDERS),
    )
    limit = fields.Integer(
        load_default=50,
        validate=validate.Range(min=1, max=100),
    )


class CreateStrategySchema(Schema):
    name = fields.String(required=True, validate=validate.Length(min=1, max=100))
    description = fields.String(required=False, allow_none=True)
    filters = fields.Nested(ScreenerFilterSchema, load_default=dict)
    sort_by = fields.String(
        load_default="marketCap",
        validate=validate.OneOf(VALID_SORT_FIELDS),
    )
    sort_order = fields.String(
        load_default="desc",
        validate=validate.OneOf(VALID_SORT_ORDERS),
    )
    sortBy = fields.String(required=False)
    sortOrder = fields.String(required=False)

    @post_load
    def handle_camel_case(self, data: dict[str, Any], **kwargs: Any) -> dict[str, Any]:
        if "sortBy" in data:
            data["sort_by"] = data.pop("sortBy")
        if "sortOrder" in data:
            data["sort_order"] = data.pop("sortOrder")
        return data


class UpdateStrategySchema(Schema):
    name = fields.String(required=False, validate=validate.Length(min=1, max=100))
    description = fields.String(required=False, allow_none=True)
    filters = fields.Nested(ScreenerFilterSchema, required=False)
    sort_by = fields.String(
        required=False,
        validate=validate.OneOf(VALID_SORT_FIELDS),
    )
    sort_order = fields.String(
        required=False,
        validate=validate.OneOf(VALID_SORT_ORDERS),
    )
    sortBy = fields.String(required=False)
    sortOrder = fields.String(required=False)

    @post_load
    def handle_camel_case(self, data: dict[str, Any], **kwargs: Any) -> dict[str, Any]:
        if "sortBy" in data:
            data["sort_by"] = data.pop("sortBy")
        if "sortOrder" in data:
            data["sort_order"] = data.pop("sortOrder")
        return data

    @validates_schema
    def validate_at_least_one_field(self, data: dict[str, Any], **kwargs: Any) -> None:
        if not data:
            raise ValidationError("At least one field must be provided for update.")
