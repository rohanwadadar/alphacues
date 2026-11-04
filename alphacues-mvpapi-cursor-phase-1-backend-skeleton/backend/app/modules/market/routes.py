from __future__ import annotations

from dataclasses import asdict, is_dataclass
from decimal import Decimal
from functools import wraps
from typing import Any

from flask import Blueprint, current_app, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.portfolio.service import PortfolioService

from app.adapters.market_data import UpstreamTimeoutError, UpstreamUnavailableError
from app.modules.market.schemas import (
    BarsQuerySchema,
    BarsResponseSchema,
    FundamentalsSchema,
    MoverSchema,
    MoversQuerySchema,
    QuoteSchema,
    SearchQuerySchema,
    SearchResultSchema,
    SnapshotItemSchema,
)
from app.modules.market.service import MarketService
from app.shared.auth import require_auth
from app.shared.cache import CacheService
from app.shared.db import db
from app.shared.exceptions import ValidationError
from app.shared.limiter import limiter, market_search_user_key, on_rate_limit_breach
from app.shared.response import json_response

market_bp = Blueprint("market", __name__, url_prefix="/api/v1/market")
dashboard_bp = Blueprint("dashboard", __name__, url_prefix="/api/v1")

quote_schema = QuoteSchema()
bars_response_schema = BarsResponseSchema()
snapshot_schema = SnapshotItemSchema(many=True)
search_schema = SearchResultSchema(many=True)
mover_schema = MoverSchema(many=True)
fundamentals_schema = FundamentalsSchema()
bars_query_schema = BarsQuerySchema()
movers_query_schema = MoversQuerySchema()
search_query_schema = SearchQuerySchema()


def _market_service() -> MarketService:
    adapter = current_app.extensions["market_data_adapter"]
    return MarketService(adapter, CacheService(), db.session)


def _serialize_payload(payload: Any) -> Any:
    if is_dataclass(payload):
        return _serialize_payload(asdict(payload))
    if isinstance(payload, list):
        return [_serialize_payload(item) for item in payload]
    if isinstance(payload, dict):
        return {key: _serialize_payload(value) for key, value in payload.items()}
    if isinstance(payload, Decimal):
        return float(payload)
    return payload


def _load_query(schema, args: dict[str, Any] | None = None) -> dict[str, Any]:
    try:
        return schema.load(args or request.args)
    except MarshmallowValidationError as exc:
        raise ValidationError(
            message="Request validation failed.",
            details=exc.normalized_messages(),
        ) from exc


def _handle_market_errors(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if request.method == "OPTIONS":
            return current_app.make_default_options_response()
        try:
            return func(*args, **kwargs)
        except UpstreamTimeoutError as exc:
            return json_response(
                status_code=504,
                error_code="UPSTREAM_TIMEOUT",
                error_message=str(exc) or "Upstream request timed out.",
            )
        except UpstreamUnavailableError as exc:
            return json_response(
                status_code=503,
                error_code="SERVICE_UNAVAILABLE",
                error_message=str(exc) or "Upstream service is unavailable.",
            )

    return wrapper


@market_bp.get("/quote")
@require_auth
@_handle_market_errors
def get_quote():
    symbol = request.args.get("symbol")
    if not symbol:
        raise ValidationError(
            message="Request validation failed.",
            details={"symbol": ["symbol is required."]},
        )
    payload = _market_service().get_quote(symbol.upper())
    return json_response(quote_schema.dump(_serialize_payload(asdict(payload))))


@market_bp.get("/bars")
@require_auth
@_handle_market_errors
def get_bars():
    data = _load_query(bars_query_schema)
    payload = _market_service().get_bars(
        data["symbol"],
        data["timeframe"],
        data["range"],
    )
    return json_response(
        bars_response_schema.dump(_serialize_payload(asdict(payload)))
    )


@market_bp.get("/snapshot")
@require_auth
@_handle_market_errors
def get_snapshot():
    symbols_param = request.args.get("symbols")
    if not symbols_param:
        raise ValidationError(
            message="Request validation failed.",
            details={"symbols": ["symbols is required."]},
        )
    symbols = [symbol.strip().upper() for symbol in symbols_param.split(",") if symbol]
    if not symbols:
        raise ValidationError(
            message="Request validation failed.",
            details={"symbols": ["symbols must contain at least one symbol."]},
        )
    if len(symbols) > 20:
        raise ValidationError(
            message="Request validation failed.",
            details={"symbols": ["symbols supports at most 20 symbols per request."]},
        )
    payload = _market_service().get_snapshot(symbols)
    return json_response(
        snapshot_schema.dump(_serialize_payload([asdict(item) for item in payload]))
    )


@market_bp.get("/search")
@require_auth
@limiter.limit(
    "30 per minute",
    key_func=market_search_user_key,
    on_breach=on_rate_limit_breach,
)
@_handle_market_errors
def search_symbols():
    data = _load_query(search_query_schema)
    payload = _market_service().search(data["q"], data["limit"])
    return json_response(
        search_schema.dump(_serialize_payload([asdict(item) for item in payload]))
    )


@market_bp.get("/movers")
@require_auth
@_handle_market_errors
def get_movers():
    data = _load_query(movers_query_schema)
    payload = _market_service().get_movers(data["sort"], data["limit"])
    return json_response(
        mover_schema.dump(_serialize_payload([asdict(item) for item in payload]))
    )


@market_bp.get("/fundamentals")
@require_auth
@_handle_market_errors
def get_fundamentals():
    symbol = request.args.get("symbol")
    if not symbol:
        raise ValidationError(
            message="Request validation failed.",
            details={"symbol": ["symbol is required."]},
        )
    payload = _market_service().get_fundamentals(symbol.upper())
    return json_response(
        fundamentals_schema.dump(_serialize_payload(asdict(payload)))
    )


@dashboard_bp.get("/dashboard")
@require_auth
@_handle_market_errors
def get_dashboard():
    user_id = int(g.user_id) if hasattr(g, "user_id") and g.user_id else None
    portfolio_data = None
    if user_id is not None:
        try:
            portfolio_data = PortfolioService.get_summary(user_id)
        except Exception:
            portfolio_data = None

    summary = _market_service().get_dashboard_summary()
    gainers_data = [asdict(item) for item in summary["gainers"]]
    losers_data = [asdict(item) for item in summary["losers"]]
    all_movers_data = gainers_data + losers_data

    resp_data = {
        "gainers": mover_schema.dump(_serialize_payload(gainers_data)),
        "losers": mover_schema.dump(_serialize_payload(losers_data)),
        "topMovers": mover_schema.dump(_serialize_payload(all_movers_data)),
        "movers": mover_schema.dump(_serialize_payload(all_movers_data)),
    }
    if portfolio_data is not None:
        resp_data["portfolio"] = portfolio_data
        resp_data["portfolioSummary"] = portfolio_data

    return json_response(resp_data)
