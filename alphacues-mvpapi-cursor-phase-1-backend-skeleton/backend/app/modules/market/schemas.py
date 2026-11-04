from __future__ import annotations

import re

from marshmallow import Schema, ValidationError, fields, validate, validates_schema

from app.adapters.protocols import VALID_RANGES, VALID_TIMEFRAMES

SYMBOL_PATTERN = re.compile(r"^[A-Z][A-Z0-9._-]{0,14}$")


class QuoteSchema(Schema):
    symbol = fields.String(required=True)
    lastPrice = fields.Float(required=True)
    changeAmount = fields.Float(required=True)
    changePercent = fields.Float(required=True)
    asOf = fields.String(required=True)


class BarItemSchema(Schema):
    timeStamp = fields.String(required=True)
    openPrice = fields.Float(required=True)
    highPrice = fields.Float(required=True)
    lowPrice = fields.Float(required=True)
    closePrice = fields.Float(required=True)
    volume = fields.Integer(required=True)


class BarsResponseSchema(Schema):
    symbol = fields.String(required=True)
    bars = fields.List(fields.Nested(BarItemSchema), required=True)


class SnapshotItemSchema(Schema):
    symbol = fields.String(required=True)
    lastPrice = fields.Float(required=True)
    changeAmount = fields.Float(required=True)
    changePercent = fields.Float(required=True)
    asOf = fields.String(required=True)


class SearchResultSchema(Schema):
    symbol = fields.String(required=True)
    name = fields.String(required=True)
    exchange = fields.String(required=True)


class MoverSchema(Schema):
    symbol = fields.String(required=True)
    name = fields.String(required=True)
    lastPrice = fields.Float(required=True)
    changePercent = fields.Float(required=True)


class FundamentalsSchema(Schema):
    symbol = fields.String(required=True)
    name = fields.String(required=True)
    marketCap = fields.Float(required=True, allow_none=True)
    peRatio = fields.Float(required=False, allow_none=True)
    eps = fields.Float(required=False, allow_none=True)
    dividendYield = fields.Float(required=False, allow_none=True)
    fiftyTwoWeekHigh = fields.Float(required=True, allow_none=True)
    fiftyTwoWeekLow = fields.Float(required=True, allow_none=True)
    description = fields.String(required=False, allow_none=True)

    # Performance & Key Statistics
    volume = fields.Integer(required=False, allow_none=True)
    avgVolume = fields.String(required=False, allow_none=True)
    openPrice = fields.Float(required=False, allow_none=True)
    prevClose = fields.Float(required=False, allow_none=True)
    rvol = fields.Float(required=False, allow_none=True)
    todaysLow = fields.Float(required=False, allow_none=True)
    todaysHigh = fields.Float(required=False, allow_none=True)
    dayRange = fields.String(required=False, allow_none=True)
    yearRange = fields.String(required=False, allow_none=True)
    expertBuyPercent = fields.Float(required=False, allow_none=True)
    expertHoldPercent = fields.Float(required=False, allow_none=True)
    expertSellPercent = fields.Float(required=False, allow_none=True)

    # Financial Overview Chart Series
    earningsPrices = fields.List(fields.Dict(), required=False, allow_none=True)
    roeSeries = fields.List(fields.Dict(), required=False, allow_none=True)
    debtEquitySeries = fields.List(fields.Dict(), required=False, allow_none=True)
    netProfitMarginSeries = fields.List(fields.Dict(), required=False, allow_none=True)
    financialStatements = fields.Dict(required=False, allow_none=True)


class BarsQuerySchema(Schema):
    symbol = fields.String(required=True)
    timeframe = fields.String(required=True)
    range = fields.String(required=True, data_key="range")

    @validates_schema
    def validate_bars_query(self, data: dict, **_kwargs) -> None:
        symbol = data.get("symbol", "")
        if not SYMBOL_PATTERN.match(symbol):
            raise ValidationError(
                {"symbol": ["symbol must match ^[A-Z][A-Z0-9._-]{0,14}$"]}
            )
        timeframe = data.get("timeframe", "")
        if timeframe not in VALID_TIMEFRAMES:
            raise ValidationError(
                {
                    "timeframe": [
                        "timeframe must be one of: "
                        + ", ".join(sorted(VALID_TIMEFRAMES))
                    ]
                }
            )
        range_value = data.get("range", "")
        if range_value not in VALID_RANGES:
            raise ValidationError(
                {
                    "range": [
                        "range must be one of: " + ", ".join(sorted(VALID_RANGES))
                    ]
                }
            )


class MoversQuerySchema(Schema):
    sort = fields.String(
        required=False,
        load_default="gainers",
        validate=validate.OneOf(["gainers", "losers", "most_active"]),
    )
    limit = fields.Integer(
        required=False,
        load_default=10,
        validate=validate.Range(min=1, max=50),
    )


class SearchQuerySchema(Schema):
    q = fields.String(required=True, validate=validate.Length(min=1))
    limit = fields.Integer(
        required=False,
        load_default=10,
        validate=validate.Range(min=1, max=50),
    )
