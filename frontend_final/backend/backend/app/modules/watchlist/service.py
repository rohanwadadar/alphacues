from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from flask import current_app
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload

from app.modules.market.service import MarketService
from app.modules.watchlist.models import Watchlist, WatchlistItem
from app.shared.cache import TTL_WATCHLIST_SUMMARY_MIN, CacheService
from app.shared.db import db
from decimal import Decimal
from app.shared.exceptions import DuplicateSymbolError, NotFoundError
from app.shared.validators import validate_symbol_input


def _format_timestamp(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _list_cache_key(user_id: int) -> str:
    return f"watchlist:list:{user_id}"


def _market_service() -> MarketService:
    adapter = current_app.extensions["market_data_adapter"]
    return MarketService(adapter, CacheService(), db.session)


def _null_quote_fields() -> dict[str, Any]:
    return {
        "lastPrice": None,
        "changeAmount": None,
        "changePercent": None,
        "asOf": None,
    }


def _quote_to_fields(quote: Any) -> dict[str, Any]:
    def _to_float(val: Any) -> float | None:
        if val is None:
            return None
        try:
            return float(val)
        except (ValueError, TypeError):
            return None

    if isinstance(quote, dict):
        last_price = quote.get("lastPrice")
        change_amount = quote.get("changeAmount")
        change_percent = quote.get("changePercent")
        as_of = quote.get("asOf")
    else:
        last_price = getattr(quote, "lastPrice", None)
        change_amount = getattr(quote, "changeAmount", None)
        change_percent = getattr(quote, "changePercent", None)
        as_of = getattr(quote, "asOf", None)

    return {
        "lastPrice": _to_float(last_price),
        "changeAmount": _to_float(change_amount),
        "changePercent": _to_float(change_percent),
        "asOf": as_of,
    }


class WatchlistService:
    @staticmethod
    def _invalidate_list_cache(user_id: int) -> None:
        CacheService().delete(_list_cache_key(user_id))

    @staticmethod
    def _get_owned_watchlist(user_id: int, watchlist_id: int) -> Watchlist:
        watchlist = db.session.scalar(
            select(Watchlist).where(
                Watchlist.watchlist_id == watchlist_id,
                Watchlist.user_id == user_id,
            )
        )
        if watchlist is None:
            raise NotFoundError(message="Watchlist was not found.")
        return watchlist

    @staticmethod
    def _watchlist_summary(watchlist: Watchlist, symbol_count: int) -> dict[str, Any]:
        return {
            "watchlistId": str(watchlist.watchlist_id),
            "name": watchlist.name,
            "symbolCount": symbol_count,
            "createdAt": _format_timestamp(watchlist.created_at),
        }

    @staticmethod
    def list_watchlists(user_id: int) -> list[Watchlist]:
        return list(
            db.session.scalars(
                select(Watchlist)
                .where(Watchlist.user_id == user_id)
                .order_by(Watchlist.created_at.desc())
            ).all()
        )

    @staticmethod
    def get_watchlist_list_data(user_id: int) -> dict[str, Any]:
        cache = CacheService()
        cache_key = _list_cache_key(user_id)
        cached = cache.get_json(cache_key)
        if cached is not None:
            return cached

        rows = db.session.execute(
            select(Watchlist, func.count(WatchlistItem.id))
            .outerjoin(
                WatchlistItem,
                WatchlistItem.watchlist_id == Watchlist.watchlist_id,
            )
            .where(Watchlist.user_id == user_id)
            .group_by(Watchlist.watchlist_id)
            .order_by(Watchlist.created_at.desc())
        ).all()

        data = {
            "watchlists": [
                WatchlistService._watchlist_summary(watchlist, symbol_count)
                for watchlist, symbol_count in rows
            ]
        }
        cache.set_json(cache_key, data, ttl_seconds=TTL_WATCHLIST_SUMMARY_MIN)
        return data

    @staticmethod
    def create_watchlist(user_id: int, name: str) -> Watchlist:
        watchlist = Watchlist(user_id=user_id, name=name.strip())
        db.session.add(watchlist)
        db.session.commit()
        WatchlistService._invalidate_list_cache(user_id)
        return watchlist

    @staticmethod
    def get_watchlist(user_id: int, watchlist_id: int) -> Watchlist:
        return WatchlistService._get_owned_watchlist(user_id, watchlist_id)

    @staticmethod
    def rename_watchlist(user_id: int, watchlist_id: int, name: str) -> Watchlist:
        watchlist = WatchlistService._get_owned_watchlist(user_id, watchlist_id)
        watchlist.name = name.strip()
        db.session.commit()
        WatchlistService._invalidate_list_cache(user_id)
        return watchlist

    @staticmethod
    def delete_watchlist(user_id: int, watchlist_id: int) -> None:
        watchlist = WatchlistService._get_owned_watchlist(user_id, watchlist_id)
        db.session.delete(watchlist)
        db.session.commit()
        WatchlistService._invalidate_list_cache(user_id)

    @staticmethod
    def add_symbol(user_id: int, watchlist_id: int, symbol: str) -> WatchlistItem:
        normalized = validate_symbol_input(symbol)
        watchlist = WatchlistService._get_owned_watchlist(user_id, watchlist_id)
        item = WatchlistItem(watchlist_id=watchlist.watchlist_id, symbol=normalized)
        db.session.add(item)
        try:
            db.session.commit()
        except IntegrityError as exc:
            db.session.rollback()
            raise DuplicateSymbolError(
                message=f"Symbol {normalized} is already in this watchlist."
            ) from exc
        WatchlistService._invalidate_list_cache(user_id)

        # Paper trading: simulate a BUY event
        try:
            from app.modules.portfolio.service import PortfolioService
            market = _market_service()
            snapshots = market.get_snapshot([normalized])
            if snapshots and hasattr(snapshots[0], "lastPrice") and snapshots[0].lastPrice is not None:
                price = Decimal(str(snapshots[0].lastPrice))
                if price > 0:
                    PortfolioService.record_event(
                        user_id=user_id,
                        symbol=normalized,
                        action="BUY",
                        price=price,
                        volume=1,
                        time_stamp=datetime.now(timezone.utc),
                    )
                else:
                    current_app.logger.warning(f"Skipping paper trade for {normalized}: price is {price}")
        except Exception as e:
            current_app.logger.warning(f"Failed to record paper trade for {normalized}: {e}")

        return item

    @staticmethod
    def remove_symbol(user_id: int, watchlist_id: int, symbol: str) -> None:
        watchlist = WatchlistService._get_owned_watchlist(user_id, watchlist_id)
        normalized = symbol.strip().upper()
        item = db.session.scalar(
            select(WatchlistItem).where(
                WatchlistItem.watchlist_id == watchlist.watchlist_id,
                WatchlistItem.symbol == normalized,
            )
        )
        if item is None:
            raise NotFoundError(message="Symbol was not found in this watchlist.")
        db.session.delete(item)
        db.session.commit()
        WatchlistService._invalidate_list_cache(user_id)

    @staticmethod
    def get_watchlist_detail(user_id: int, watchlist_id: int) -> dict[str, Any]:
        watchlist = db.session.scalar(
            select(Watchlist)
            .options(selectinload(Watchlist.items))
            .where(
                Watchlist.watchlist_id == watchlist_id,
                Watchlist.user_id == user_id,
            )
        )
        if watchlist is None:
            raise NotFoundError(message="Watchlist was not found.")

        symbols = [item.symbol for item in watchlist.items]
        quotes_by_symbol: dict[str, dict[str, Any]] = {}

        if symbols:
            try:
                snapshots = _market_service().get_snapshot(symbols)
                for snapshot in snapshots:
                    sym = getattr(snapshot, "symbol", None) if not isinstance(snapshot, dict) else snapshot.get("symbol")
                    if sym:
                        quotes_by_symbol[sym] = _quote_to_fields(snapshot)
            except Exception as e:
                current_app.logger.warning(f"Failed to fetch market snapshots for watchlist detail: {e}")
                quotes_by_symbol = {}

        items: list[dict[str, Any]] = []
        for item in watchlist.items:
            quote_fields = quotes_by_symbol.get(item.symbol, _null_quote_fields())
            items.append(
                {
                    "symbol": item.symbol,
                    "addedAt": _format_timestamp(item.added_at),
                    **quote_fields,
                }
            )

        return {
            "watchlistId": str(watchlist.watchlist_id),
            "name": watchlist.name,
            "createdAt": _format_timestamp(watchlist.created_at),
            "items": items,
        }

    @staticmethod
    def watchlist_summary_for(watchlist: Watchlist) -> dict[str, Any]:
        symbol_count = db.session.scalar(
            select(func.count())
            .select_from(WatchlistItem)
            .where(WatchlistItem.watchlist_id == watchlist.watchlist_id)
        )
        return WatchlistService._watchlist_summary(watchlist, int(symbol_count or 0))

    @staticmethod
    def watchlist_item_to_dict(item: WatchlistItem) -> dict[str, Any]:
        return {
            "symbol": item.symbol,
            "addedAt": _format_timestamp(item.added_at),
        }
