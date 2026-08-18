from __future__ import annotations

import time
from dataclasses import asdict, is_dataclass
from decimal import Decimal
from typing import Any

from sqlalchemy.orm import Session

from app.adapters.protocols import (
    BarsPayload,
    FundamentalsPayload,
    MarketDataSource,
    MoverPayload,
    QuotePayload,
    SearchResult,
    SnapshotPayload,
)
from app.modules.market.models import StockTick
from app.shared.cache import CacheService

SHORT_BAR_TIMEFRAMES = frozenset({"5min", "15min", "30min"})
QUOTE_TTL_SECONDS = 5
SNAPSHOT_TTL_SECONDS = 30
SEARCH_TTL_SECONDS = 60
MOVERS_TTL_SECONDS = 60
BARS_SHORT_TTL_SECONDS = 60
BARS_LONG_TTL_SECONDS = 300
FUNDAMENTALS_TTL_SECONDS = 21600
LOCK_TTL_SECONDS = 2
LOCK_RETRY_COUNT = 3
LOCK_RETRY_SLEEP_SECONDS = 0.1


def _payload_to_dict(payload: Any) -> Any:
    if is_dataclass(payload):
        return _payload_to_dict(asdict(payload))
    if isinstance(payload, list):
        return [_payload_to_dict(item) for item in payload]
    if isinstance(payload, dict):
        return {key: _payload_to_dict(value) for key, value in payload.items()}
    if isinstance(payload, Decimal):
        return str(payload)
    return payload


def _dict_to_quote(data: dict[str, Any]) -> QuotePayload:
    return QuotePayload(
        symbol=data["symbol"],
        lastPrice=Decimal(str(data["lastPrice"])),
        changeAmount=Decimal(str(data["changeAmount"])),
        changePercent=Decimal(str(data["changePercent"])),
        asOf=data["asOf"],
    )


def _dict_to_bars(data: dict[str, Any]) -> BarsPayload:
    from app.adapters.protocols import BarItem

    bars = [
        BarItem(
            timeStamp=bar["timeStamp"],
            openPrice=Decimal(str(bar["openPrice"])),
            highPrice=Decimal(str(bar["highPrice"])),
            lowPrice=Decimal(str(bar["lowPrice"])),
            closePrice=Decimal(str(bar["closePrice"])),
            volume=int(bar["volume"]),
        )
        for bar in data["bars"]
    ]
    return BarsPayload(symbol=data["symbol"], bars=bars)


def _dict_to_snapshot(data: dict[str, Any]) -> SnapshotPayload:
    return SnapshotPayload(
        symbol=data["symbol"],
        lastPrice=Decimal(str(data["lastPrice"])),
        changeAmount=Decimal(str(data["changeAmount"])),
        changePercent=Decimal(str(data["changePercent"])),
        asOf=data["asOf"],
    )


def _dict_to_mover(data: dict[str, Any]) -> MoverPayload:
    return MoverPayload(
        symbol=data["symbol"],
        name=data["name"],
        lastPrice=Decimal(str(data["lastPrice"])),
        changePercent=Decimal(str(data["changePercent"])),
    )


def _dict_to_search_result(data: dict[str, Any]) -> SearchResult:
    return SearchResult(
        symbol=data["symbol"],
        name=data["name"],
        exchange=data["exchange"],
    )


def _dict_to_fundamentals(data: dict[str, Any]) -> FundamentalsPayload:
    return FundamentalsPayload(
        symbol=data["symbol"],
        name=data["name"],
        marketCap=Decimal(str(data["marketCap"])),
        peRatio=Decimal(str(data["peRatio"])) if data.get("peRatio") is not None else None,
        eps=Decimal(str(data["eps"])) if data.get("eps") is not None else None,
        dividendYield=(
            Decimal(str(data["dividendYield"]))
            if data.get("dividendYield") is not None
            else None
        ),
        fiftyTwoWeekHigh=Decimal(str(data["fiftyTwoWeekHigh"])),
        fiftyTwoWeekLow=Decimal(str(data["fiftyTwoWeekLow"])),
        description=data.get("description"),
    )


class MarketService:
    def __init__(
        self,
        adapter: MarketDataSource,
        cache: CacheService,
        db_session: Session,
    ) -> None:
        self._adapter = adapter
        self._cache = cache
        self._session = db_session

    def get_quote(self, symbol: str) -> QuotePayload:
        cache_key = f"market:quote:{symbol}"
        cached = self._cache.get_json(cache_key)
        if cached is not None:
            return _dict_to_quote(cached)

        lock_key = f"lock:market:quote:{symbol}"
        if self._cache.acquire_lock(lock_key, ttl_seconds=LOCK_TTL_SECONDS):
            try:
                cached = self._cache.get_json(cache_key)
                if cached is not None:
                    return _dict_to_quote(cached)
                payload = self._adapter.get_quote(symbol)
                self._cache.set_json(
                    cache_key,
                    _payload_to_dict(payload),
                    ttl_seconds=QUOTE_TTL_SECONDS,
                )
                return payload
            finally:
                self._cache.release_lock(lock_key)

        for _ in range(LOCK_RETRY_COUNT):
            time.sleep(LOCK_RETRY_SLEEP_SECONDS)
            cached = self._cache.get_json(cache_key)
            if cached is not None:
                return _dict_to_quote(cached)

        payload = self._adapter.get_quote(symbol)
        self._cache.set_json(
            cache_key,
            _payload_to_dict(payload),
            ttl_seconds=QUOTE_TTL_SECONDS,
        )
        return payload

    def upsert_tick(self, quote: QuotePayload) -> None:
        StockTick.upsert_tick(self._session, quote)
    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        cache_key = f"market:bars:{symbol}:{timeframe}:{range}"
        cached = self._cache.get_json(cache_key)
        if cached is not None:
            return _dict_to_bars(cached)

        payload = self._adapter.get_bars(symbol, timeframe, range)
        StockTick.upsert_bars(self._session, payload)
        ttl = (
            BARS_SHORT_TTL_SECONDS
            if timeframe in SHORT_BAR_TIMEFRAMES
            else BARS_LONG_TTL_SECONDS
        )
        self._cache.set_json(
            cache_key,
            _payload_to_dict(payload),
            ttl_seconds=ttl,
        )
        return payload

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        results: list[SnapshotPayload] = []
        uncached: list[str] = []

        for symbol in symbols:
            cache_key = f"market:snapshot:{symbol}"
            cached = self._cache.get_json(cache_key)
            if cached is not None:
                results.append(_dict_to_snapshot(cached))
            else:
                uncached.append(symbol)

        if uncached:
            fetched = self._adapter.get_snapshot(uncached)
            for item in fetched:
                cache_key = f"market:snapshot:{item.symbol}"
                self._cache.set_json(
                    cache_key,
                    _payload_to_dict(item),
                    ttl_seconds=SNAPSHOT_TTL_SECONDS,
                )
                results.append(item)

        return results

    def get_movers(self, sort: str, limit: int) -> list[MoverPayload]:
        cache_key = f"market:movers:{sort}:{limit}"
        cached = self._cache.get_json(cache_key)
        if cached is not None:
            return [_dict_to_mover(item) for item in cached]

        payload = self._adapter.get_movers(sort, limit)
        self._cache.set_json(
            cache_key,
            _payload_to_dict(payload),
            ttl_seconds=MOVERS_TTL_SECONDS,
        )
        return payload

    def search(self, q: str, limit: int) -> list[SearchResult]:
        cache_key = f"market:search:{q}:{limit}"
        cached = self._cache.get_json(cache_key)
        if cached is not None:
            return [_dict_to_search_result(item) for item in cached]

        payload = self._adapter.search(q, limit)
        self._cache.set_json(
            cache_key,
            _payload_to_dict(payload),
            ttl_seconds=SEARCH_TTL_SECONDS,
        )
        return payload

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        cache_key = f"market:fundamentals:{symbol}"
        cached = self._cache.get_json(cache_key)
        if cached is not None:
            return _dict_to_fundamentals(cached)

        lock_key = f"lock:market:fundamentals:{symbol}"
        if self._cache.acquire_lock(lock_key, ttl_seconds=LOCK_TTL_SECONDS):
            try:
                cached = self._cache.get_json(cache_key)
                if cached is not None:
                    return _dict_to_fundamentals(cached)
                payload = self._adapter.get_fundamentals(symbol)
                self._cache.set_json(
                    cache_key,
                    _payload_to_dict(payload),
                    ttl_seconds=FUNDAMENTALS_TTL_SECONDS,
                )
                return payload
            finally:
                self._cache.release_lock(lock_key)

        for _ in range(LOCK_RETRY_COUNT):
            time.sleep(LOCK_RETRY_SLEEP_SECONDS)
            cached = self._cache.get_json(cache_key)
            if cached is not None:
                return _dict_to_fundamentals(cached)

        payload = self._adapter.get_fundamentals(symbol)
        self._cache.set_json(
            cache_key,
            _payload_to_dict(payload),
            ttl_seconds=FUNDAMENTALS_TTL_SECONDS,
        )
        return payload

    def get_dashboard_summary(self) -> dict[str, list[MoverPayload]]:
        gainers = self.get_movers("gainers", 5)
        losers = self.get_movers("losers", 5)
        return {"gainers": gainers, "losers": losers}
