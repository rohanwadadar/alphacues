from __future__ import annotations

import json
import logging
import random
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any

from flask import Flask

try:
    import websocket
except ImportError:  # pragma: no cover
    websocket = None  # type: ignore[assignment]
from app.adapters.protocols import (
    BarItem,
    BarsPayload,
    FundamentalsPayload,
    MarketDataSource,
    MoverPayload,
    QuotePayload,
    SearchResult,
    SnapshotPayload,
)

logger = logging.getLogger(__name__)

ALPACA_DATA_BASE_URL = "https://data.alpaca.markets"
ALPACA_API_BASE_URL = "https://api.alpaca.markets"
ALPHA_VANTAGE_BASE_URL = "https://www.alphavantage.co/query"

REQUEST_TIMEOUT_SECONDS = 5
MAX_RETRIES = 4

TIMEFRAME_TO_ALPACA = {
    "5min": "5Min",
    "15min": "15Min",
    "30min": "30Min",
    "1hour": "1Hour",
    "1day": "1Day",
    "1week": "1Week",
    "1month": "1Month",
}

RANGE_TO_DAYS = {
    "1D": 0,
    "1W": 7,
    "1M": 30,
    "3M": 90,
    "6M": 180,
    "1Y": 365,
    "5Y": 365 * 5,
    "MAX": 365 * 10,
}


class UpstreamTimeoutError(Exception):
    pass


class UpstreamUnavailableError(Exception):
    pass


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _to_decimal(value: Any) -> Decimal:
    return Decimal(str(value))


def _iso_z(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _range_start(range_value: str) -> datetime:
    now = _utcnow()
    days = RANGE_TO_DAYS[range_value]
    if days == 0:
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    return now - timedelta(days=days)


def _backoff_sleep(attempt: int) -> None:
    base = min(2**attempt, 8)
    jitter = random.uniform(0, 0.5)
    time.sleep(base + jitter)


class _HttpClient:
    def __init__(self, *, headers: dict[str, str] | None = None) -> None:
        self._headers = headers or {}

    def get_json(self, url: str, *, params: dict[str, Any] | None = None) -> Any:
        if params:
            query = urllib.parse.urlencode(params)
            url = f"{url}?{query}"
        last_error: Exception | None = None
        for attempt in range(MAX_RETRIES):
            try:
                request = urllib.request.Request(
                    url,
                    headers=self._headers,
                    method="GET",
                )
                with urllib.request.urlopen(
                    request, timeout=REQUEST_TIMEOUT_SECONDS
                ) as response:
                    body = response.read().decode("utf-8")
                    return json.loads(body) if body else {}
            except TimeoutError as exc:
                raise UpstreamTimeoutError("Upstream request timed out.") from exc
            except urllib.error.HTTPError as exc:
                if exc.code == 429 or exc.code >= 500:
                    last_error = exc
                    if attempt < MAX_RETRIES - 1:
                        _backoff_sleep(attempt)
                        continue
                    if exc.code == 429:
                        raise UpstreamUnavailableError(
                            "Upstream rate limit exceeded."
                        ) from exc
                    raise UpstreamUnavailableError(
                        "Upstream service returned a server error."
                    ) from exc
                raise UpstreamUnavailableError(
                    f"Upstream request failed with status {exc.code}."
                ) from exc
            except urllib.error.URLError as exc:
                raise UpstreamUnavailableError(
                    "Unable to connect to upstream service."
                ) from exc
            except json.JSONDecodeError as exc:
                raise UpstreamUnavailableError(
                    "Upstream returned invalid JSON."
                ) from exc
        if last_error is not None:
            raise UpstreamUnavailableError(
                "Upstream service is unavailable after retries."
            ) from last_error
        raise UpstreamUnavailableError("Upstream request failed.")


class AlpacaMarketDataAdapter(MarketDataSource):
    def __init__(
        self,
        *,
        api_key: str,
        secret_key: str,
        data_feed: str,
    ) -> None:
        self._feed = data_feed
        self._client = _HttpClient(
            headers={
                "APCA-API-KEY-ID": api_key,
                "APCA-API-SECRET-KEY": secret_key,
            }
        )

    def get_quote(self, symbol: str) -> QuotePayload:
        upper = symbol.upper()
        quote_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/{upper}/quotes/latest"
        quote_data = self._client.get_json(quote_url, params={"feed": self._feed})
        quote = quote_data.get("quote") or {}
        ask = quote.get("ap")
        bid = quote.get("bp")
        if ask is not None and bid is not None:
            last_price = (float(ask) + float(bid)) / 2
        else:
            last_price = ask or bid or 0

        snapshot_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/snapshots"
        snapshot_data = self._client.get_json(
            snapshot_url,
            params={"symbols": upper, "feed": self._feed},
        )
        snapshot = (snapshot_data.get("snapshots") or {}).get(upper) or {}
        prev_close = (
            (snapshot.get("prevDailyBar") or {}).get("c")
            or (snapshot.get("dailyBar") or {}).get("o")
            or last_price
        )
        change_amount = float(last_price) - float(prev_close)
        change_percent = (
            (change_amount / float(prev_close)) * 100 if float(prev_close) else 0.0
        )
        as_of = quote.get("t") or _iso_z(_utcnow())

        return QuotePayload(
            symbol=upper,
            lastPrice=_to_decimal(last_price),
            changeAmount=_to_decimal(change_amount),
            changePercent=_to_decimal(change_percent),
            asOf=as_of.replace("+00:00", "Z") if as_of.endswith("+00:00") else as_of,
        )

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        upper = symbol.upper()
        alpaca_timeframe = TIMEFRAME_TO_ALPACA[timeframe]
        start = _range_start(range)
        end = _utcnow()
        bars_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/bars"
        data = self._client.get_json(
            bars_url,
            params={
                "symbols": upper,
                "timeframe": alpaca_timeframe,
                "start": _iso_z(start),
                "end": _iso_z(end),
                "feed": self._feed,
                "limit": 10000,
            },
        )
        raw_bars = (data.get("bars") or {}).get(upper) or []
        bars = [
            BarItem(
                timeStamp=(bar.get("t") or "").replace("+00:00", "Z"),
                openPrice=_to_decimal(bar.get("o", 0)),
                highPrice=_to_decimal(bar.get("h", 0)),
                lowPrice=_to_decimal(bar.get("l", 0)),
                closePrice=_to_decimal(bar.get("c", 0)),
                volume=int(bar.get("v", 0)),
            )
            for bar in raw_bars
        ]
        return BarsPayload(symbol=upper, bars=bars)

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        if not symbols:
            return []
        upper_symbols = [symbol.upper() for symbol in symbols]
        snapshot_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/snapshots"
        data = self._client.get_json(
            snapshot_url,
            params={
                "symbols": ",".join(upper_symbols),
                "feed": self._feed,
            },
        )
        snapshots = data.get("snapshots") or {}
        results: list[SnapshotPayload] = []
        for symbol in upper_symbols:
            snapshot = snapshots.get(symbol) or {}
            latest_trade = snapshot.get("latestTrade") or {}
            daily_bar = snapshot.get("dailyBar") or {}
            prev_daily = snapshot.get("prevDailyBar") or {}
            last_price = latest_trade.get("p") or daily_bar.get("c") or 0
            prev_close = prev_daily.get("c") or daily_bar.get("o") or last_price
            change_amount = float(last_price) - float(prev_close)
            change_percent = (
                (change_amount / float(prev_close)) * 100 if float(prev_close) else 0.0
            )
            as_of = latest_trade.get("t") or daily_bar.get("t") or _iso_z(_utcnow())
            results.append(
                SnapshotPayload(
                    symbol=symbol,
                    lastPrice=_to_decimal(last_price),
                    changeAmount=_to_decimal(change_amount),
                    changePercent=_to_decimal(change_percent),
                    asOf=as_of.replace("+00:00", "Z")
                    if isinstance(as_of, str) and as_of.endswith("+00:00")
                    else as_of,
                )
            )
        return results

    def search(self, q: str, limit: int = 10) -> list[SearchResult]:
        assets_url = f"{ALPACA_API_BASE_URL}/v2/assets"
        assets = self._client.get_json(assets_url, params={"status": "active"})
        needle = q.casefold()
        matches: list[SearchResult] = []
        for asset in assets:
            symbol = asset.get("symbol") or ""
            name = asset.get("name") or ""
            if needle in symbol.casefold() or needle in name.casefold():
                matches.append(
                    SearchResult(
                        symbol=symbol,
                        name=name,
                        exchange=asset.get("exchange") or "",
                    )
                )
            if len(matches) >= limit:
                break
        return matches

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]:
        if sort == "most_active":
            url = f"{ALPACA_DATA_BASE_URL}/v1beta1/screener/stocks/most-actives"
            data = self._client.get_json(url, params={"top": limit})
            raw_items = data.get("most_actives") or data.get("symbols") or []
        else:
            url = f"{ALPACA_DATA_BASE_URL}/v1beta1/screener/stocks/movers"
            market_type = "gainers" if sort == "gainers" else "losers"
            data = self._client.get_json(
                url,
                params={"top": limit, "market_type": market_type},
            )
            raw_items = data.get("movers") or data.get("gainers") or data.get("losers") or []

        results: list[MoverPayload] = []
        for item in raw_items:
            symbol = item.get("symbol") or ""
            if not symbol:
                continue
            change_percent = item.get("percent_change") or item.get("change_percent") or 0
            price = item.get("price") or item.get("last") or 0
            results.append(
                MoverPayload(
                    symbol=symbol,
                    name=item.get("name") or symbol,
                    lastPrice=_to_decimal(price),
                    changePercent=_to_decimal(change_percent),
                )
            )
            if len(results) >= limit:
                break
        return results

    def get_all_assets(self) -> list[dict]:
        """Return all active assets from Alpaca GET /v2/assets."""
        assets_url = f"{ALPACA_API_BASE_URL}/v2/assets"
        return self._client.get_json(assets_url, params={"status": "active"})

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        raise NotImplementedError(
            "Fundamentals are provided by AlphaVantageAdapter."
        )

    def stream_quotes(
        self,
        *,
        stream_url: str,
        on_quote: Callable[[QuotePayload], None],
        should_stop: Callable[[], bool],
    ) -> None:
        if websocket is None:
            raise RuntimeError("websocket-client is required for quote streaming")

        api_key = self._client._headers["APCA-API-KEY-ID"]
        secret_key = self._client._headers["APCA-API-SECRET-KEY"]

        def on_message(_ws: Any, message: str) -> None:
            try:
                payload = json.loads(message)
            except json.JSONDecodeError:
                return
            messages = payload if isinstance(payload, list) else [payload]
            for item in messages:
                if item.get("T") != "q":
                    continue
                symbol = (item.get("S") or "").upper()
                if not symbol:
                    continue
                ask = item.get("ap")
                bid = item.get("bp")
                if ask is not None and bid is not None:
                    last_price = (float(ask) + float(bid)) / 2
                else:
                    last_price = float(ask or bid or 0)
                as_of = item.get("t") or _iso_z(_utcnow())
                if isinstance(as_of, str) and as_of.endswith("+00:00"):
                    as_of = as_of.replace("+00:00", "Z")
                on_quote(
                    QuotePayload(
                        symbol=symbol,
                        lastPrice=_to_decimal(last_price),
                        changeAmount=Decimal("0"),
                        changePercent=Decimal("0"),
                        asOf=as_of,
                    )
                )

        def on_open(ws_app: Any) -> None:
            ws_app.send(
                json.dumps({"action": "auth", "key": api_key, "secret": secret_key})
            )
            ws_app.send(json.dumps({"action": "subscribe", "quotes": ["*"]}))

        ws_app = websocket.WebSocketApp(
            stream_url,
            on_message=on_message,
            on_open=on_open,
        )
        while not should_stop():
            ws_app.run_forever(ping_interval=20, ping_timeout=10)
            if should_stop():
                break
            raise ConnectionError("Alpaca quote stream disconnected")


class AlphaVantageAdapter(MarketDataSource):
    def __init__(self, *, api_key: str) -> None:
        self._api_key = api_key
        self._client = _HttpClient()

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        data = self._client.get_json(
            ALPHA_VANTAGE_BASE_URL,
            params={
                "function": "OVERVIEW",
                "symbol": symbol.upper(),
                "apikey": self._api_key,
            },
        )
        if not data or data.get("Symbol") is None:
            raise UpstreamUnavailableError(
                "Alpha Vantage fundamentals response was empty."
            )

        def optional_decimal(key: str) -> Decimal | None:
            value = data.get(key)
            if value in (None, "", "None", "-"):
                return None
            return _to_decimal(value)

        return FundamentalsPayload(
            symbol=data.get("Symbol", symbol.upper()),
            name=data.get("Name") or symbol.upper(),
            marketCap=_to_decimal(data.get("MarketCapitalization") or 0),
            peRatio=optional_decimal("PERatio"),
            eps=optional_decimal("EPS"),
            dividendYield=optional_decimal("DividendYield"),
            fiftyTwoWeekHigh=_to_decimal(data.get("52WeekHigh") or 0),
            fiftyTwoWeekLow=_to_decimal(data.get("52WeekLow") or 0),
            description=data.get("Description"),
        )

    def get_quote(self, symbol: str) -> QuotePayload:
        raise NotImplementedError

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        raise NotImplementedError

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        raise NotImplementedError

    def search(self, q: str, limit: int = 10) -> list[SearchResult]:
        raise NotImplementedError

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]:
        raise NotImplementedError


class CompositeMarketDataAdapter(MarketDataSource):
    def __init__(
        self,
        alpaca: AlpacaMarketDataAdapter,
        av: AlphaVantageAdapter,
    ) -> None:
        self._alpaca = alpaca
        self._av = av

    def get_quote(self, symbol: str) -> QuotePayload:
        return self._alpaca.get_quote(symbol)

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        return self._alpaca.get_bars(symbol, timeframe, range)

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        return self._alpaca.get_snapshot(symbols)

    def search(self, q: str, limit: int = 10) -> list[SearchResult]:
        return self._alpaca.search(q, limit)

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]:
        return self._alpaca.get_movers(sort, limit)

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        return self._av.get_fundamentals(symbol)

    def get_all_assets(self) -> list[dict]:
        return self._alpaca.get_all_assets()

    def stream_quotes(
        self,
        *,
        stream_url: str,
        on_quote: Callable[[QuotePayload], None],
        should_stop: Callable[[], bool],
    ) -> None:
        self._alpaca.stream_quotes(
            stream_url=stream_url,
            on_quote=on_quote,
            should_stop=should_stop,
        )

def create_market_data_adapter(app: Flask) -> MarketDataSource:
    if app.config.get("MOCK_EXTERNAL_SERVICES"):
        from app.adapters.fake_market_data import FakeMarketDataAdapter

        return FakeMarketDataAdapter()

    alpaca = AlpacaMarketDataAdapter(
        api_key=app.config["ALPACA_API_KEY"],
        secret_key=app.config["ALPACA_SECRET_KEY"],
        data_feed=app.config["ALPACA_DATA_FEED"],
    )
    av = AlphaVantageAdapter(api_key=app.config["ALPHA_VANTAGE_API_KEY"])
    return CompositeMarketDataAdapter(alpaca=alpaca, av=av)
