from __future__ import annotations

from typing import Any

from app.adapters.protocols import MarketDataSource
from app.modules.screener.models import ScreenerStrategy
from app.shared.db import db
from app.shared.exceptions import NotFoundError
from app.shared.validators import parse_cursor, parse_limit

from decimal import Decimal

DEFAULT_SYMBOLS = ("AAPL", "MSFT", "GOOGL", "TSLA")


def _normalize_filters(filters: dict[str, Any] | None) -> dict[str, Any]:
    if not filters:
        return {}
    clean = {}
    for k, v in filters.items():
        if isinstance(v, Decimal):
            clean[k] = float(v) if "." in str(v) else int(v)
        else:
            clean[k] = v
    return clean


class ScreenerService:
    @staticmethod
    def run_scan(
        market_adapter: MarketDataSource,
        filters: dict[str, Any],
        sort_by: str = "marketCap",
        sort_order: str = "desc",
        limit: int = 50,
        symbols: tuple[str, ...] | list[str] | None = None,
    ) -> dict[str, Any]:
        target_symbols = list(symbols or DEFAULT_SYMBOLS)
        candidates: list[dict[str, Any]] = []

        for sym in target_symbols:
            try:
                fund = market_adapter.get_fundamentals(sym)
                quote = market_adapter.get_quote(sym)
            except Exception:
                continue

            item = {
                "symbol": fund.symbol,
                "name": fund.name,
                "marketCap": float(fund.marketCap) if fund.marketCap is not None else 0.0,
                "peRatio": float(fund.peRatio) if fund.peRatio is not None else None,
                "eps": float(fund.eps) if fund.eps is not None else None,
                "dividendYield": (
                    float(fund.dividendYield) if fund.dividendYield is not None else None
                ),
                "fiftyTwoWeekHigh": float(fund.fiftyTwoWeekHigh),
                "fiftyTwoWeekLow": float(fund.fiftyTwoWeekLow),
                "price": float(quote.lastPrice),
                "changePercent": float(quote.changePercent),
                "changeAmount": float(quote.changeAmount),
                "exchange": getattr(fund, "exchange", "NASDAQ"),
            }

            if not ScreenerService._matches_filters(item, filters):
                continue

            candidates.append(item)

        reverse = sort_order == "desc"

        def _sort_key(item: dict[str, Any]) -> tuple[int, Any, str]:
            val = item.get(sort_by)
            if val is None:
                # Place None values at the end regardless of sort order
                return (1, 0, item["symbol"])
            if reverse:
                # For descending, negate numeric values if applicable
                return (0, -val if isinstance(val, (int, float)) else val, item["symbol"])
            return (0, val, item["symbol"])

        candidates.sort(key=_sort_key)
        truncated = candidates[:limit]

        return {
            "total": len(candidates),
            "limit": limit,
            "items": truncated,
        }

    @staticmethod
    def _matches_filters(item: dict[str, Any], filters: dict[str, Any]) -> bool:
        if not filters:
            return True

        if "marketCapMin" in filters and filters["marketCapMin"] is not None:
            if item["marketCap"] < float(filters["marketCapMin"]):
                return False

        if "marketCapMax" in filters and filters["marketCapMax"] is not None:
            if item["marketCap"] > float(filters["marketCapMax"]):
                return False

        if "peRatioMin" in filters and filters["peRatioMin"] is not None:
            if item["peRatio"] is None or item["peRatio"] < float(filters["peRatioMin"]):
                return False

        if "peRatioMax" in filters and filters["peRatioMax"] is not None:
            if item["peRatio"] is None or item["peRatio"] > float(filters["peRatioMax"]):
                return False

        if "priceMin" in filters and filters["priceMin"] is not None:
            if item["price"] < float(filters["priceMin"]):
                return False

        if "priceMax" in filters and filters["priceMax"] is not None:
            if item["price"] > float(filters["priceMax"]):
                return False

        if "changePercentMin" in filters and filters["changePercentMin"] is not None:
            if item["changePercent"] < float(filters["changePercentMin"]):
                return False

        if "changePercentMax" in filters and filters["changePercentMax"] is not None:
            if item["changePercent"] > float(filters["changePercentMax"]):
                return False

        if "dividendYieldMin" in filters and filters["dividendYieldMin"] is not None:
            if item["dividendYield"] is None or item["dividendYield"] < float(
                filters["dividendYieldMin"]
            ):
                return False

        if "exchange" in filters and filters["exchange"]:
            if item["exchange"].upper() != filters["exchange"].upper():
                return False

        return True

    @staticmethod
    def create_strategy(
        user_id: int,
        name: str,
        description: str | None = None,
        filters: dict[str, Any] | None = None,
        sort_by: str = "marketCap",
        sort_order: str = "desc",
    ) -> ScreenerStrategy:
        strategy = ScreenerStrategy(
            user_id=user_id,
            name=name,
            description=description,
            filters=_normalize_filters(filters),
            sort_by=sort_by,
            sort_order=sort_order,
        )
        db.session.add(strategy)
        db.session.commit()
        return strategy

    @staticmethod
    def get_user_strategies(user_id: int) -> list[ScreenerStrategy]:
        return (
            db.session.query(ScreenerStrategy)
            .filter(ScreenerStrategy.user_id == user_id)
            .order_by(ScreenerStrategy.strategy_id.desc())
            .all()
        )

    @staticmethod
    def get_user_strategies_paginated(
        user_id: int, limit: int = 20, cursor: str | None = None
    ) -> tuple[list[ScreenerStrategy], str | None]:
        query = db.session.query(ScreenerStrategy).filter(
            ScreenerStrategy.user_id == user_id
        )

        parsed_cursor = parse_cursor(cursor)
        if parsed_cursor is not None:
            try:
                cursor_id = int(parsed_cursor)
                query = query.filter(ScreenerStrategy.strategy_id < cursor_id)
            except ValueError:
                pass

        rows = (
            query.order_by(ScreenerStrategy.strategy_id.desc())
            .limit(limit + 1)
            .all()
        )

        next_cursor = None
        if len(rows) > limit:
            next_cursor = str(rows[limit - 1].strategy_id)
            rows = rows[:limit]

        return rows, next_cursor

    @staticmethod
    def get_strategy(user_id: int, strategy_id: int) -> ScreenerStrategy:
        strategy = (
            db.session.query(ScreenerStrategy)
            .filter(
                ScreenerStrategy.strategy_id == strategy_id,
                ScreenerStrategy.user_id == user_id,
            )
            .first()
        )
        if strategy is None:
            raise NotFoundError("Screener strategy not found.")
        return strategy

    @staticmethod
    def update_strategy(
        user_id: int, strategy_id: int, updates: dict[str, Any]
    ) -> ScreenerStrategy:
        strategy = ScreenerService.get_strategy(user_id, strategy_id)
        if "name" in updates:
            strategy.name = updates["name"]
        if "description" in updates:
            strategy.description = updates["description"]
        if "filters" in updates:
            strategy.filters = _normalize_filters(updates["filters"])
        if "sort_by" in updates:
            strategy.sort_by = updates["sort_by"]
        if "sort_order" in updates:
            strategy.sort_order = updates["sort_order"]

        db.session.commit()
        return strategy

    @staticmethod
    def delete_strategy(user_id: int, strategy_id: int) -> None:
        strategy = ScreenerService.get_strategy(user_id, strategy_id)
        db.session.delete(strategy)
        db.session.commit()

    @staticmethod
    def strategy_to_dict(strategy: ScreenerStrategy) -> dict[str, Any]:
        return {
            "strategyId": strategy.strategy_id,
            "userId": strategy.user_id,
            "name": strategy.name,
            "description": strategy.description,
            "filters": strategy.filters,
            "sortBy": strategy.sort_by,
            "sortOrder": strategy.sort_order,
            "createdAt": strategy.created_at.isoformat(),
            "updatedAt": strategy.updated_at.isoformat(),
        }
