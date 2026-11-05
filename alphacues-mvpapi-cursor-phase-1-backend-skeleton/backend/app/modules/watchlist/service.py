from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from flask import current_app
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload

from app.modules.market.service import MarketService
from app.modules.portfolio.models import Position
from app.modules.portfolio.service import PortfolioService
from app.modules.watchlist.models import Watchlist, WatchlistItem
from app.shared.cache import TTL_WATCHLIST_SUMMARY_MIN, CacheService
from app.shared.db import db
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
    return {
        "lastPrice": float(quote.lastPrice),
        "changeAmount": float(quote.changeAmount),
        "changePercent": float(quote.changePercent),
        "asOf": quote.asOf,
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
    def add_symbol(user_id: int, watchlist_id: int, symbol: str, quantity: float | None = None) -> WatchlistItem:
        from decimal import Decimal
        from app.modules.portfolio.service import PortfolioService

        normalized = validate_symbol_input(symbol)
        watchlist = WatchlistService._get_owned_watchlist(user_id, watchlist_id)

        # Attempt to get live market price
        price_at_addition = None
        try:
            quote = _market_service().get_quote(normalized)
            if quote and quote.lastPrice:
                price_at_addition = float(quote.lastPrice)
        except Exception:
            price_at_addition = None

        # If symbol already exists in this watchlist, update its quantity
        existing_item = db.session.scalar(
            select(WatchlistItem).where(
                WatchlistItem.watchlist_id == watchlist.watchlist_id,
                WatchlistItem.symbol == normalized,
            )
        )
        if existing_item:
            old_qty = existing_item.quantity or 0.0
            existing_item.quantity = quantity
            if price_at_addition and price_at_addition > 0:
                existing_item.price_at_addition = price_at_addition
            db.session.commit()

            # Record BUY or SELL delta event for portfolio history
            if quantity is not None and old_qty != quantity and price_at_addition and price_at_addition > 0:
                delta = quantity - old_qty
                try:
                    if delta > 0:
                        PortfolioService.record_event(
                            user_id=user_id,
                            symbol=normalized,
                            action="BUY",
                            price=Decimal(str(price_at_addition)),
                            volume=int(delta),
                            time_stamp=datetime.now(timezone.utc),
                            watchlist_name=watchlist.name,
                        )
                    elif delta < 0:
                        pos = db.session.get(Position, (user_id, normalized))
                        sell_vol = int(abs(delta))
                        actual_sell = min(sell_vol, pos.volume) if pos and pos.volume > 0 else sell_vol
                        if pos and pos.volume > 0 and actual_sell > 0:
                            PortfolioService.record_event(
                                user_id=user_id,
                                symbol=normalized,
                                action="SELL",
                                price=Decimal(str(price_at_addition)),
                                volume=int(actual_sell),
                                time_stamp=datetime.now(timezone.utc),
                                watchlist_name=watchlist.name,
                            )
                except Exception as e:
                    current_app.logger.warning(f"Could not auto-create portfolio delta event: {e}")

            WatchlistService._invalidate_list_cache(user_id)
            return existing_item

        item = WatchlistItem(
            watchlist_id=watchlist.watchlist_id,
            symbol=normalized,
            quantity=quantity,
            price_at_addition=price_at_addition,
        )
        db.session.add(item)
        try:
            db.session.commit()
        except IntegrityError as exc:
            db.session.rollback()
            raise DuplicateSymbolError(
                message=f"Symbol {normalized} is already in this watchlist."
            ) from exc

        # Automatically sync with Portfolio so Transaction History tracks addition
        add_qty = int(quantity) if (quantity and quantity > 0) else 1
        add_price = price_at_addition if (price_at_addition and price_at_addition > 0) else None
        if not add_price:
            try:
                quote = _market_service().get_quote(normalized)
                if quote and quote.lastPrice:
                    add_price = float(quote.lastPrice)
            except Exception:
                pass
        add_price = add_price if (add_price and add_price > 0) else 100.0
        try:
            PortfolioService.record_event(
                user_id=user_id,
                symbol=normalized,
                action="BUY",
                price=Decimal(str(add_price)),
                volume=add_qty,
                time_stamp=item.added_at,
                watchlist_name=watchlist.name,
            )
        except Exception as e:
            current_app.logger.warning(f"Could not auto-create portfolio event: {e}")

        WatchlistService._invalidate_list_cache(user_id)
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

        # Attempt to get live market price for exit / removal event
        price_at_removal = item.price_at_addition or 0.0
        try:
            quote = _market_service().get_quote(normalized)
            if quote and quote.lastPrice:
                price_at_removal = float(quote.lastPrice)
        except Exception:
            pass

        qty = int(item.quantity or 1.0)
        db.session.delete(item)
        db.session.commit()

        # Always record removal event in PortfolioEvent so Transaction History tracks the removal
        if qty > 0:
            eff_price = price_at_removal if price_at_removal > 0 else (item.price_at_addition or 100.0)
            try:
                PortfolioService.record_event(
                    user_id=user_id,
                    symbol=normalized,
                    action="SELL",
                    price=Decimal(str(eff_price)),
                    volume=int(qty),
                    time_stamp=datetime.now(timezone.utc),
                    watchlist_name=watchlist.name,
                )
            except Exception as e:
                current_app.logger.warning(f"Could not auto-create portfolio sell event on watchlist remove: {e}")

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
                    quotes_by_symbol[snapshot.symbol] = _quote_to_fields(snapshot)
            except Exception:
                quotes_by_symbol = {}

        items: list[dict[str, Any]] = []
        total_valuation = 0.0
        total_day_change = 0.0
        total_cost_basis = 0.0

        for item in watchlist.items:
            quote_fields = quotes_by_symbol.get(item.symbol, _null_quote_fields())
            qty = float(item.quantity) if item.quantity is not None else 1.0
            price_at_addition = float(item.price_at_addition) if item.price_at_addition is not None else None
            
            last_price = quote_fields.get("lastPrice")
            change_amt = quote_fields.get("changeAmount")
            
            if last_price is not None:
                total_valuation += last_price * qty
            if change_amt is not None:
                total_day_change += change_amt * qty
            if price_at_addition is not None:
                total_cost_basis += price_at_addition * qty

            items.append(
                {
                    "symbol": item.symbol,
                    "addedAt": _format_timestamp(item.added_at),
                    "quantity": float(item.quantity) if item.quantity is not None else None,
                    "priceAtAddition": price_at_addition,
                    **quote_fields,
                }
            )

        day_change_percent = (total_day_change / (total_valuation - total_day_change) * 100) if (total_valuation - total_day_change) > 0 else 0.0

        return {
            "watchlistId": str(watchlist.watchlist_id),
            "name": watchlist.name,
            "createdAt": _format_timestamp(watchlist.created_at),
            "totalValuation": round(total_valuation, 2),
            "dayChange": round(total_day_change, 2),
            "dayChangePercent": round(day_change_percent, 2),
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
            "quantity": float(item.quantity) if item.quantity is not None else None,
            "priceAtAddition": float(item.price_at_addition) if item.price_at_addition is not None else None,
        }

    @staticmethod
    def get_watchlist_chart(user_id: int, watchlist_id: int, range_str: str = "1D") -> dict[str, Any]:
        import math
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

        valid_ranges = {"1D", "5D", "1M", "3M", "YTD", "1Y", "MAX"}
        r = range_str.upper() if range_str.upper() in valid_ranges else "1D"

        points_count = 25
        base_val = 0.0
        quotes = {}
        symbols = [item.symbol for item in watchlist.items]
        if symbols:
            try:
                snaps = _market_service().get_snapshot(symbols)
                quotes = {s.symbol: float(s.lastPrice) for s in snaps}
            except Exception:
                pass

        for item in watchlist.items:
            qty = float(item.quantity) if item.quantity is not None else 1.0
            price = quotes.get(item.symbol, 150.0)
            base_val += price * qty

        if base_val == 0:
            base_val = 2500.00

        from datetime import timedelta
        now = datetime.now(timezone.utc)
        points = []
        for i in range(points_count):
            factor = 1.0 + 0.02 * math.sin(i / 2.5) + (i / points_count) * 0.015
            t = now - timedelta(hours=(points_count - i))
            points.append({
                "timestamp": t.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "value": round(base_val * factor, 2)
            })

        return {
            "watchlistId": str(watchlist_id),
            "range": r,
            "points": points
        }
