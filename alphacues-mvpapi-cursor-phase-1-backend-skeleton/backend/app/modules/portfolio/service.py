from __future__ import annotations

import base64
import json
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any

from flask import current_app
from sqlalchemy import and_, delete, or_, select

from app.modules.market.service import MarketService
from app.modules.portfolio.models import (
    PORTFOLIO_ACTIONS,
    PortfolioEvent,
    PortfolioSnapshot,
    Position,
)
from app.shared.cache import CacheService
from app.shared.db import db
from app.shared.exceptions import EventNotFoundError, ValidationError
from app.shared.validators import pagination_meta, validate_symbol_input

# TODO(product): confirm the real settlement / editable window with product.
EDITABLE_WINDOW_HOURS = 24
IDEMPOTENCY_TTL_SECONDS = 86400
ZERO = Decimal("0")
SIX_PLACES = Decimal("0.000001")


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _format_timestamp(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _cursor_sort_value(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _decimal_to_number(value: Decimal) -> float:
    return float(value.quantize(SIX_PLACES))


def _idempotency_cache_key(user_id: int, idempotency_key: str) -> str:
    return f"idempotency:portfolio:{user_id}:{idempotency_key}"


def _encode_event_cursor(time_stamp: datetime, event_id: uuid.UUID) -> str:
    payload = {"v": _cursor_sort_value(time_stamp), "id": str(event_id)}
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(encoded).decode("ascii")


def _decode_event_cursor(raw_cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        decoded = base64.urlsafe_b64decode(raw_cursor.encode("ascii")).decode("utf-8")
        payload = json.loads(decoded)
        sort_value = str(payload["v"])
        event_id = uuid.UUID(str(payload["id"]))
        time_stamp = datetime.fromisoformat(sort_value.replace("Z", "+00:00"))
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        raise ValidationError(
            message="cursor is invalid.",
            details={"field": "cursor", "value": raw_cursor},
        ) from exc
    return time_stamp, event_id


def _market_service() -> MarketService:
    adapter = current_app.extensions["market_data_adapter"]
    return MarketService(adapter, CacheService(), db.session)


class PortfolioService:
    @staticmethod
    def event_to_dict(event: PortfolioEvent) -> dict[str, Any]:
        return {
            "eventId": str(event.event_id),
            "symbol": event.symbol,
            "action": event.action,
            "price": _decimal_to_number(event.price),
            "volume": event.volume,
            "time_stamp": _format_timestamp(event.time_stamp),
        }

    @staticmethod
    def snapshot_to_dict(snapshot: PortfolioSnapshot) -> dict[str, Any]:
        return {
            "time_stamp": _format_timestamp(snapshot.time_stamp),
            "symbol": snapshot.symbol,
            "quantity": snapshot.quantity,
            "total_price": _decimal_to_number(snapshot.total_price),
        }

    @staticmethod
    def _get_owned_event(user_id: int, event_id: uuid.UUID) -> PortfolioEvent:
        event = db.session.scalar(
            select(PortfolioEvent).where(
                PortfolioEvent.event_id == event_id,
                PortfolioEvent.user_id == user_id,
            )
        )
        if event is None:
            raise EventNotFoundError(message="Portfolio event was not found.")
        return event

    @staticmethod
    def _assert_timestamp_within_editable_window(time_stamp: datetime) -> None:
        event_time = time_stamp
        if event_time.tzinfo is None:
            event_time = event_time.replace(tzinfo=timezone.utc)
        deadline = event_time + timedelta(hours=EDITABLE_WINDOW_HOURS)
        if _utcnow() > deadline:
            raise ValidationError(message="Event is outside the editable window.")

    @staticmethod
    def _assert_within_editable_window(event: PortfolioEvent) -> None:
        PortfolioService._assert_timestamp_within_editable_window(event.time_stamp)

    @staticmethod
    def _get_or_create_position(user_id: int, symbol: str) -> Position:
        position = db.session.get(Position, (user_id, symbol))
        if position is None:
            position = Position(
                user_id=user_id,
                symbol=symbol,
                volume=0,
                total_price=ZERO,
            )
            db.session.add(position)
        return position

    @staticmethod
    def _apply_buy(position: Position, price: Decimal, volume: int) -> None:
        position.volume += volume
        position.total_price += price * volume
        position.updated_at = _utcnow()

    @staticmethod
    def _apply_sell(position: Position, price: Decimal, volume: int) -> None:
        if position.volume < volume:
            raise ValidationError(message="Insufficient holdings for SELL.")
        if position.volume == 0:
            raise ValidationError(message="Insufficient holdings for SELL.")
        avg_cost = position.total_price / Decimal(position.volume)
        position.total_price -= avg_cost * volume
        position.volume -= volume
        if position.volume == 0:
            position.total_price = ZERO
        position.updated_at = _utcnow()

    @staticmethod
    def _write_snapshot(user_id: int, symbol: str, position: Position) -> None:
        now = _utcnow()
        existing = db.session.scalar(
            select(PortfolioSnapshot).where(
                PortfolioSnapshot.user_id == user_id,
                PortfolioSnapshot.time_stamp == now,
                PortfolioSnapshot.symbol == symbol,
            )
        )
        if existing is not None:
            existing.quantity = position.volume
            existing.total_price = position.total_price
            return

        snapshot = PortfolioSnapshot(
            user_id=user_id,
            time_stamp=now,
            symbol=symbol,
            quantity=position.volume,
            total_price=position.total_price,
        )
        db.session.add(snapshot)

    @staticmethod
    def _recompute_position(user_id: int, symbol: str) -> Position:
        events = list(
            db.session.scalars(
                select(PortfolioEvent)
                .where(
                    PortfolioEvent.user_id == user_id,
                    PortfolioEvent.symbol == symbol,
                )
                .order_by(PortfolioEvent.time_stamp.asc(), PortfolioEvent.event_id.asc())
            ).all()
        )

        position = PortfolioService._get_or_create_position(user_id, symbol)
        position.volume = 0
        position.total_price = ZERO

        for event in events:
            if event.action == "BUY":
                PortfolioService._apply_buy(position, event.price, event.volume)
            else:
                PortfolioService._apply_sell(position, event.price, event.volume)

        if position.volume == 0:
            position.total_price = ZERO
        position.updated_at = _utcnow()
        return position

    @staticmethod
    def record_event(
        user_id: int,
        *,
        symbol: str,
        action: str,
        price: Decimal,
        volume: int,
        time_stamp: datetime,
        idempotency_key: str | None = None,
    ) -> PortfolioEvent:
        if action not in PORTFOLIO_ACTIONS:
            raise ValidationError(message="Request validation failed.")

        normalized_symbol = validate_symbol_input(symbol)

        if idempotency_key:
            cache = CacheService()
            cache_key = _idempotency_cache_key(user_id, idempotency_key)
            cached_event_id = cache.get(cache_key)
            if cached_event_id is not None:
                existing = db.session.scalar(
                    select(PortfolioEvent).where(
                        PortfolioEvent.event_id == uuid.UUID(cached_event_id),
                        PortfolioEvent.user_id == user_id,
                    )
                )
                if existing is not None:
                    return existing

        if time_stamp.tzinfo is None:
            time_stamp = time_stamp.replace(tzinfo=timezone.utc)

        PortfolioService._assert_timestamp_within_editable_window(time_stamp)

        event = PortfolioEvent(
            user_id=user_id,
            symbol=normalized_symbol,
            action=action,
            price=price,
            volume=volume,
            time_stamp=time_stamp,
        )
        db.session.add(event)

        position = PortfolioService._get_or_create_position(user_id, normalized_symbol)
        if action == "BUY":
            PortfolioService._apply_buy(position, price, volume)
        else:
            PortfolioService._apply_sell(position, price, volume)

        PortfolioService._write_snapshot(user_id, normalized_symbol, position)
        db.session.commit()

        if idempotency_key:
            CacheService().set(
                _idempotency_cache_key(user_id, idempotency_key),
                str(event.event_id),
                ttl_seconds=IDEMPOTENCY_TTL_SECONDS,
            )

        return event

    @staticmethod
    def update_event(
        user_id: int,
        event_id: uuid.UUID,
        *,
        symbol: str,
        action: str,
        price: Decimal,
        volume: int,
        time_stamp: datetime | None = None,
    ) -> PortfolioEvent:
        if action not in PORTFOLIO_ACTIONS:
            raise ValidationError(message="Request validation failed.")

        event = PortfolioService._get_owned_event(user_id, event_id)
        PortfolioService._assert_within_editable_window(event)

        old_symbol = event.symbol
        normalized_symbol = validate_symbol_input(symbol)

        event.symbol = normalized_symbol
        event.action = action
        event.price = price
        event.volume = volume
        if time_stamp is not None:
            if time_stamp.tzinfo is None:
                time_stamp = time_stamp.replace(tzinfo=timezone.utc)
            event.time_stamp = time_stamp

        symbols_to_recompute = {old_symbol, normalized_symbol}
        for sym in symbols_to_recompute:
            position = PortfolioService._recompute_position(user_id, sym)
            PortfolioService._write_snapshot(user_id, sym, position)

        db.session.commit()
        return event

    @staticmethod
    def delete_event(user_id: int, event_id: uuid.UUID) -> None:
        event = PortfolioService._get_owned_event(user_id, event_id)
        PortfolioService._assert_within_editable_window(event)

        symbol = event.symbol
        db.session.delete(event)

        position = PortfolioService._recompute_position(user_id, symbol)
        PortfolioService._write_snapshot(user_id, symbol, position)
        db.session.commit()

    @staticmethod
    def get_summary(user_id: int) -> dict[str, Any]:
        positions = list(
            db.session.scalars(
                select(Position).where(
                    Position.user_id == user_id,
                    Position.volume > 0,
                )
            ).all()
        )

        symbols = [position.symbol for position in positions]
        quotes_by_symbol: dict[str, Any] = {}

        if symbols:
            try:
                snapshots = _market_service().get_snapshot(symbols)
                quotes_by_symbol = {item.symbol: item for item in snapshots}
            except Exception:
                quotes_by_symbol = {}

        total_value = ZERO
        total_profit = ZERO
        total_cost_basis = ZERO
        day_change = ZERO

        for position in positions:
            quote = quotes_by_symbol.get(position.symbol)
            if quote is None:
                continue
            market_value = quote.lastPrice * position.volume
            unrealized_pl = market_value - position.total_price
            day_change_pos = quote.changeAmount * position.volume

            total_value += market_value
            total_profit += unrealized_pl
            total_cost_basis += position.total_price
            day_change += day_change_pos

        if total_cost_basis > ZERO:
            total_return = (total_value - total_cost_basis) / total_cost_basis * 100
        else:
            total_return = ZERO

        now = _utcnow()
        return {
            "portfolioId": str(user_id),
            "totalValue": _decimal_to_number(total_value),
            "availableBalance": _decimal_to_number(ZERO),
            "totalProfit": _decimal_to_number(total_profit),
            "totalReturn": _decimal_to_number(total_return),
            "dayChange": _decimal_to_number(day_change),
            "asOf": _format_timestamp(now),
        }

    @staticmethod
    def list_transactions(
        user_id: int,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        query = (
            select(PortfolioEvent)
            .where(PortfolioEvent.user_id == user_id)
            .order_by(
                PortfolioEvent.time_stamp.desc(),
                PortfolioEvent.event_id.desc(),
            )
        )

        if cursor is not None:
            cursor_time, cursor_event_id = _decode_event_cursor(cursor)
            query = query.where(
                or_(
                    PortfolioEvent.time_stamp < cursor_time,
                    and_(
                        PortfolioEvent.time_stamp == cursor_time,
                        PortfolioEvent.event_id < cursor_event_id,
                    ),
                )
            )

        rows = list(db.session.scalars(query.limit(limit + 1)).all())
        has_more = len(rows) > limit
        page = rows[:limit]
        next_cursor = None
        if has_more and page:
            last = page[-1]
            next_cursor = _encode_event_cursor(last.time_stamp, last.event_id)

        transactions = [PortfolioService.event_to_dict(event) for event in page]
        return {"transactions": transactions}, pagination_meta(next_cursor=next_cursor)

    @staticmethod
    def get_history(user_id: int) -> list[PortfolioSnapshot]:
        return list(
            db.session.scalars(
                select(PortfolioSnapshot)
                .where(PortfolioSnapshot.user_id == user_id)
                .order_by(
                    PortfolioSnapshot.time_stamp.asc(),
                    PortfolioSnapshot.symbol.asc(),
                )
            ).all()
        )

    @staticmethod
    def compute_realized_pl(
        user_id: int,
        symbol: str,
        *,
        up_to_event_id: uuid.UUID | None = None,
    ) -> Decimal:
        """Helper for tests — realized P/L is not stored or returned in MVP summary."""
        events = list(
            db.session.scalars(
                select(PortfolioEvent)
                .where(
                    PortfolioEvent.user_id == user_id,
                    PortfolioEvent.symbol == symbol,
                )
                .order_by(PortfolioEvent.time_stamp.asc(), PortfolioEvent.event_id.asc())
            ).all()
        )

        volume = 0
        total_price = ZERO
        realized = ZERO

        for event in events:
            if event.action == "BUY":
                volume += event.volume
                total_price += event.price * event.volume
            else:
                if volume < event.volume:
                    break
                avg_cost = total_price / Decimal(volume)
                realized += (event.price - avg_cost) * event.volume
                total_price -= avg_cost * event.volume
                volume -= event.volume
                if volume == 0:
                    total_price = ZERO
            if up_to_event_id is not None and event.event_id == up_to_event_id:
                break

        return realized
