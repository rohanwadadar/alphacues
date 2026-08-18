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
from app.modules.market.stock_universe import StockAsset
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

    def search_local(self, q: str, limit: int = 20) -> list[dict[str, str]]:
        """Search the local stock_universe table.

        Prioritises symbol-prefix matches over name-substring matches.
        Falls back to returning popular stocks when *q* is empty.
        """
        import logging

        logger = logging.getLogger(__name__)

        if not q or not q.strip():
            rows = (
                self._session.query(StockAsset)
                .filter(StockAsset.tradable.is_(True))
                .order_by(StockAsset.symbol)
                .limit(limit)
                .all()
            )
            return [row.to_dict() for row in rows]

        needle = q.strip()
        needle_upper = needle.upper()
        needle_lower = needle.lower()

        # 1. Exact symbol match
        exact = (
            self._session.query(StockAsset)
            .filter(
                StockAsset.symbol == needle_upper,
                StockAsset.tradable.is_(True),
            )
            .first()
        )

        # 2. Symbol prefix matches (e.g. "AA" → AAPL, AAL, …)
        prefix_rows = (
            self._session.query(StockAsset)
            .filter(
                StockAsset.symbol.like(f"{needle_upper}%"),
                StockAsset.tradable.is_(True),
            )
            .order_by(StockAsset.symbol)
            .limit(limit)
            .all()
        )

        # 3. Name substring matches
        name_rows = (
            self._session.query(StockAsset)
            .filter(
                StockAsset.name.ilike(f"%{needle_lower}%"),
                StockAsset.tradable.is_(True),
            )
            .order_by(StockAsset.symbol)
            .limit(limit)
            .all()
        )

        # Combine: exact first, then prefix, then name (deduplicated)
        seen: set[str] = set()
        results: list[dict[str, str]] = []

        def _add(row: StockAsset) -> None:
            if row.symbol not in seen and len(results) < limit:
                seen.add(row.symbol)
                results.append(row.to_dict())

        if exact:
            _add(exact)
        for row in prefix_rows:
            _add(row)
        for row in name_rows:
            _add(row)

        return results

    def sync_stock_universe(self) -> int:
        """Fetch all active assets from Alpaca and upsert into stock_universe.

        Returns the number of assets synced.
        """
        import logging
        from datetime import datetime, timezone

        logger = logging.getLogger(__name__)

        try:
            assets = self._adapter.get_all_assets()
        except Exception:
            logger.warning("Could not fetch assets from Alpaca; using built-in list.")
            assets = _BUILTIN_STOCKS

        count = 0
        now = datetime.now(timezone.utc)
        for asset in assets:
            symbol = asset.get("symbol") or ""
            if not symbol:
                continue
            existing = self._session.get(StockAsset, symbol)
            if existing:
                existing.name = asset.get("name") or existing.name
                existing.exchange = asset.get("exchange") or existing.exchange
                existing.asset_class = asset.get("class") or existing.asset_class
                existing.tradable = asset.get("tradable", True)
                existing.updated_at = now
            else:
                self._session.add(
                    StockAsset(
                        symbol=symbol,
                        name=asset.get("name") or symbol,
                        exchange=asset.get("exchange") or "",
                        asset_class=asset.get("class") or "us_equity",
                        tradable=asset.get("tradable", True),
                        updated_at=now,
                    )
                )
            count += 1
            if count % 500 == 0:
                self._session.flush()
        self._session.commit()
        logger.info("Synced %d assets into stock_universe.", count)
        return count


# Built-in fallback list when Alpaca API is unavailable
_BUILTIN_STOCKS = [
    {"symbol": "AAPL", "name": "Apple Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "MSFT", "name": "Microsoft Corporation", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "GOOGL", "name": "Alphabet Inc Class A", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "GOOG", "name": "Alphabet Inc Class C", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "AMZN", "name": "Amazon.com Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "NVDA", "name": "NVIDIA Corporation", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "META", "name": "Meta Platforms Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "TSLA", "name": "Tesla Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "BRK.B", "name": "Berkshire Hathaway Inc Class B", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "JPM", "name": "JPMorgan Chase & Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "V", "name": "Visa Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "UNH", "name": "UnitedHealth Group Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "XOM", "name": "Exxon Mobil Corporation", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "MA", "name": "Mastercard Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "JNJ", "name": "Johnson & Johnson", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "PG", "name": "Procter & Gamble Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "HD", "name": "Home Depot Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "AVGO", "name": "Broadcom Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "CVX", "name": "Chevron Corporation", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "MRK", "name": "Merck & Co Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "ABBV", "name": "AbbVie Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "PEP", "name": "PepsiCo Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "KO", "name": "Coca-Cola Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "COST", "name": "Costco Wholesale Corporation", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ADBE", "name": "Adobe Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "WMT", "name": "Walmart Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "CRM", "name": "Salesforce Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "BAC", "name": "Bank of America Corp", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "TMO", "name": "Thermo Fisher Scientific Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "CSCO", "name": "Cisco Systems Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "NFLX", "name": "Netflix Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ACN", "name": "Accenture Plc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "AMD", "name": "Advanced Micro Devices Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "INTC", "name": "Intel Corporation", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ORCL", "name": "Oracle Corporation", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "IBM", "name": "International Business Machines Corp", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "QCOM", "name": "Qualcomm Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "TXN", "name": "Texas Instruments Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "INTU", "name": "Intuit Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "NOW", "name": "ServiceNow Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "PYPL", "name": "PayPal Holdings Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SBUX", "name": "Starbucks Corporation", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "DIS", "name": "Walt Disney Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "BA", "name": "Boeing Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "NKE", "name": "Nike Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "GS", "name": "Goldman Sachs Group Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "UBER", "name": "Uber Technologies Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "SQ", "name": "Block Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "SHOP", "name": "Shopify Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "SNAP", "name": "Snap Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "PLTR", "name": "Palantir Technologies Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "COIN", "name": "Coinbase Global Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "RIVN", "name": "Rivian Automotive Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "LCID", "name": "Lucid Group Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SOFI", "name": "SoFi Technologies Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "RBLX", "name": "Roblox Corporation", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "DKNG", "name": "DraftKings Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ABNB", "name": "Airbnb Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SPOT", "name": "Spotify Technology SA", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "ZM", "name": "Zoom Video Communications Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ROKU", "name": "Roku Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "CRWD", "name": "CrowdStrike Holdings Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SNOW", "name": "Snowflake Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "NET", "name": "Cloudflare Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "DDOG", "name": "Datadog Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "PATH", "name": "UiPath Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "MDB", "name": "MongoDB Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "PANW", "name": "Palo Alto Networks Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ZS", "name": "Zscaler Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "OKTA", "name": "Okta Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SPY", "name": "SPDR S&P 500 ETF Trust", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "QQQ", "name": "Invesco QQQ Trust", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "IWM", "name": "iShares Russell 2000 ETF", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "DIA", "name": "SPDR Dow Jones Industrial Average ETF", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "VTI", "name": "Vanguard Total Stock Market ETF", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "VOO", "name": "Vanguard S&P 500 ETF", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "GLD", "name": "SPDR Gold Trust", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "SLV", "name": "iShares Silver Trust", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "ARKK", "name": "ARK Innovation ETF", "exchange": "ARCA", "class": "us_equity", "tradable": True},
    {"symbol": "GME", "name": "GameStop Corp", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "AMC", "name": "AMC Entertainment Holdings Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "HOOD", "name": "Robinhood Markets Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "ARM", "name": "Arm Holdings Plc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "SMCI", "name": "Super Micro Computer Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "MSTR", "name": "MicroStrategy Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "LLY", "name": "Eli Lilly and Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "NVO", "name": "Novo Nordisk A/S", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "WFC", "name": "Wells Fargo & Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "C", "name": "Citigroup Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "MS", "name": "Morgan Stanley", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "T", "name": "AT&T Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "VZ", "name": "Verizon Communications Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "TMUS", "name": "T-Mobile US Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "PFE", "name": "Pfizer Inc", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "MRNA", "name": "Moderna Inc", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "BNTX", "name": "BioNTech SE", "exchange": "NASDAQ", "class": "us_equity", "tradable": True},
    {"symbol": "F", "name": "Ford Motor Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
    {"symbol": "GM", "name": "General Motors Co", "exchange": "NYSE", "class": "us_equity", "tradable": True},
]
