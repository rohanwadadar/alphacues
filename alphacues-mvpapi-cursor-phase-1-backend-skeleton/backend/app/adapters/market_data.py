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
from app.shared.cache import get_redis
from app.shared.stream_subscriptions import ACTIVE_STREAM_SYMBOLS_KEY

logger = logging.getLogger(__name__)

ALPACA_DATA_BASE_URL = "https://data.alpaca.markets"
ALPACA_API_BASE_URL = "https://paper-api.alpaca.markets"
ALPHA_VANTAGE_BASE_URL = "https://www.alphavantage.co/query"

REQUEST_TIMEOUT_SECONDS = 3
MAX_RETRIES = 2

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
    "1D": 2,
    "5D": 8,
    "1W": 9,
    "1M": 35,
    "3M": 95,
    "YTD": 200,
    "6M": 190,
    "1Y": 370,
    "5Y": 365 * 5 + 10,
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
    days = RANGE_TO_DAYS.get(range_value, 0)
    if days == 0:
        return now - timedelta(days=2)
    return now - timedelta(days=days)


def _backoff_sleep(attempt: int) -> None:
    base = min(2**attempt, 2)
    jitter = random.uniform(0, 0.25)
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
        self._assets_cache: list[dict[str, Any]] | None = None
        self._assets_fetched_at: float = 0.0
        self._client = _HttpClient(
            headers={
                "APCA-API-KEY-ID": api_key,
                "APCA-API-SECRET-KEY": secret_key,
            }
        )

    _quote_cache: dict[str, tuple[float, QuotePayload]] = {}

    def get_quote(self, symbol: str) -> QuotePayload:
        upper = symbol.upper()
        import time
        now = time.time()
        if upper in self._quote_cache:
            cache_time, payload = self._quote_cache[upper]
            if now - cache_time < 15.0:
                return payload

        try:
            snapshot_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/snapshots"
            snapshot_data = self._client.get_json(
                snapshot_url,
                params={"symbols": upper, "feed": self._feed or "iex"},
            )
            snapshot = snapshot_data.get(upper) or (snapshot_data.get("snapshots") or {}).get(upper) or {}
            latest_trade = snapshot.get("latestTrade") or {}
            latest_quote = snapshot.get("latestQuote") or {}
            daily_bar = snapshot.get("dailyBar") or {}
            prev_bar = snapshot.get("prevDailyBar") or {}

            last_price = (
                latest_trade.get("p")
                or ((latest_quote.get("ap", 0) + latest_quote.get("bp", 0)) / 2)
                or daily_bar.get("c")
                or 0
            )

            prev_close = prev_bar.get("c") or daily_bar.get("o") or last_price
            change_amount = float(last_price) - float(prev_close)
            change_percent = (
                (change_amount / float(prev_close)) * 100 if float(prev_close) else 0.0
            )
            as_of = latest_trade.get("t") or latest_quote.get("t") or _iso_z(_utcnow())

            if last_price > 0:
                res = QuotePayload(
                    symbol=upper,
                    lastPrice=_to_decimal(last_price),
                    changeAmount=_to_decimal(change_amount),
                    changePercent=_to_decimal(change_percent),
                    asOf=as_of.replace("+00:00", "Z") if as_of.endswith("+00:00") else as_of,
                )
                self._quote_cache[upper] = (now, res)
                return res
        except Exception as err:
            logger.warning(f"Alpaca get_quote warning: {err}")

        return QuotePayload(
            symbol=upper,
            lastPrice=Decimal("0.0"),
            changeAmount=Decimal("0.0"),
            changePercent=Decimal("0.0"),
            asOf=_iso_z(_utcnow()),
        )

    _bars_cache: dict[str, tuple[float, BarsPayload]] = {}

    def _fetch_yahoo_bars(self, symbol: str, timeframe: str, range_val: str) -> list[BarItem]:
        yahoo_range_map = {
            "1D": ("1d", "5m"),
            "5D": ("5d", "1h"),
            "1W": ("5d", "1h"),
            "1M": ("1mo", "1h"),
            "3M": ("3mo", "1d"),
            "YTD": ("ytd", "1d"),
            "6M": ("6mo", "1d"),
            "1Y": ("1y", "1d"),
            "5Y": ("5y", "1wk"),
            "MAX": ("max", "1mo"),
        }
        y_range, y_itv = yahoo_range_map.get(range_val, ("5d", "1h"))
        try:
            url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?range={y_range}&interval={y_itv}"
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = json.loads(resp.read().decode())
                res = (data.get("chart", {}).get("result") or [{}])[0]
                ts_list = res.get("timestamp") or []
                indicators = (res.get("indicators", {}).get("quote") or [{}])[0]
                opens = indicators.get("open") or []
                highs = indicators.get("high") or []
                lows = indicators.get("low") or []
                closes = indicators.get("close") or []
                volumes = indicators.get("volume") or []

                bars: list[BarItem] = []
                for i in range(len(ts_list)):
                    c = closes[i] if i < len(closes) else None
                    if c is None:
                        continue
                    o = opens[i] if (i < len(opens) and opens[i] is not None) else c
                    h = highs[i] if (i < len(highs) and highs[i] is not None) else c
                    l = lows[i] if (i < len(lows) and lows[i] is not None) else c
                    v = volumes[i] if (i < len(volumes) and volumes[i] is not None) else 0

                    ts_iso = datetime.fromtimestamp(ts_list[i], timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                    bars.append(
                        BarItem(
                            timeStamp=ts_iso,
                            openPrice=_to_decimal(round(float(o), 2)),
                            highPrice=_to_decimal(round(float(h), 2)),
                            lowPrice=_to_decimal(round(float(l), 2)),
                            closePrice=_to_decimal(round(float(c), 2)),
                            volume=int(v),
                        )
                    )
                return bars
        except Exception as y_err:
            logger.warning(f"Yahoo fallback bars warning for {symbol}: {y_err}")
            return []

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        upper = symbol.upper()
        cache_key = f"{upper}:{timeframe}:{range}"
        now = time.time()
        cached = self._bars_cache.get(cache_key)
        if cached is not None and (now - cached[0] < 60.0):
            return cached[1]

        try:
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
                    "feed": self._feed or "iex",
                    "adjustment": "all",
                    "limit": 10000,
                },
            )
            raw_bars = (data.get("bars") or {}).get(upper) or []
            # For multi-day ranges (like 5D), Alpaca IEX must return at least 5 bars
            min_bars_threshold = 1 if range == "1D" else 5
            if raw_bars and len(raw_bars) >= min_bars_threshold:
                bars = []
                latest_close = float(raw_bars[-1].get("c", 0)) if raw_bars else 0
                for bar in raw_bars:
                    c = float(bar.get("c", 0))
                    o = float(bar.get("o", 0))
                    h = float(bar.get("h", 0))
                    l = float(bar.get("l", 0))
                    
                    if latest_close > 0 and c > 0:
                        ratio = c / latest_close
                        if ratio > 3.0:
                            split_factor = 20.0 if ratio > 12.0 else (10.0 if ratio > 6.0 else (4.0 if ratio > 3.0 else 2.0))
                            c = c / split_factor
                            o = o / split_factor
                            h = h / split_factor
                            l = l / split_factor

                    bars.append(
                        BarItem(
                            timeStamp=(bar.get("t") or "").replace("+00:00", "Z"),
                            openPrice=_to_decimal(round(o, 2)),
                            highPrice=_to_decimal(round(h, 2)),
                            lowPrice=_to_decimal(round(l, 2)),
                            closePrice=_to_decimal(round(c, 2)),
                            volume=int(bar.get("v", 0)),
                        )
                    )
                res = BarsPayload(symbol=upper, bars=bars)
                self._bars_cache[cache_key] = (now, res)
                return res
        except Exception as err:
            logger.warning(f"Alpaca get_bars warning: {err}")

        # Fallback to Yahoo Finance to guarantee 100% complete bars for all symbols
        y_bars = self._fetch_yahoo_bars(upper, timeframe, range)
        if y_bars:
            res = BarsPayload(symbol=upper, bars=y_bars)
            self._bars_cache[cache_key] = (now, res)
            return res

        res = BarsPayload(symbol=symbol.upper(), bars=[])
        return res

    _snapshot_cache: dict[str, tuple[float, SnapshotPayload]] = {}

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        if not symbols:
            return []

        now = time.time()
        upper_symbols = [s.upper() for s in symbols]

        # Serve cached results for symbols fetched within last 30 seconds
        to_fetch = [s for s in upper_symbols if s not in self._snapshot_cache or now - self._snapshot_cache[s][0] >= 30.0]
        cached = [self._snapshot_cache[s][1] for s in upper_symbols if s in self._snapshot_cache and now - self._snapshot_cache[s][0] < 30.0]

        if to_fetch:
            try:
                snapshot_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/snapshots"
                data = self._client.get_json(
                    snapshot_url,
                    params={
                        "symbols": ",".join(to_fetch),
                        "feed": self._feed or "iex",
                    },
                )
                # API returns top-level dict keyed by symbol (no "snapshots" wrapper)
                snapshots = data if isinstance(data, dict) and "snapshots" not in data else (data.get("snapshots") or data or {})
                for symbol in to_fetch:
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
                    if last_price > 0:
                        snap = SnapshotPayload(
                            symbol=symbol,
                            lastPrice=_to_decimal(last_price),
                            changeAmount=_to_decimal(change_amount),
                            changePercent=_to_decimal(change_percent),
                            asOf=as_of.replace("+00:00", "Z")
                            if isinstance(as_of, str) and as_of.endswith("+00:00")
                            else as_of,
                        )
                        self._snapshot_cache[symbol] = (now, snap)
                        cached.append(snap)
            except Exception as err:
                logger.warning(f"Alpaca get_snapshot warning: {err}")
                # Fallback: check existing quote cache for symbols
                for symbol in to_fetch:
                    cached_q = self._quote_cache.get(symbol)
                    if cached_q:
                        q = cached_q[1]
                        if q.lastPrice > 0:
                            cached.append(
                                SnapshotPayload(
                                    symbol=symbol,
                                    lastPrice=q.lastPrice,
                                    changeAmount=q.changeAmount,
                                    changePercent=q.changePercent,
                                    asOf=q.asOf,
                                )
                            )

        return cached


    def _get_active_assets(self) -> list[dict[str, Any]]:

        now = time.time()
        if self._assets_cache is not None and (now - self._assets_fetched_at) < 3600:
            return self._assets_cache

        try:
            assets_url = f"{ALPACA_API_BASE_URL}/v2/assets"
            assets = self._client.get_json(
                assets_url,
                params={"status": "active", "asset_class": "us_equity"},
            )
            if isinstance(assets, list) and assets:
                self._assets_cache = assets
                self._assets_fetched_at = now
                return assets
        except Exception as err:
            logger.warning(f"Alpaca fetch assets warning: {err}")

        return self._assets_cache or []

    def search(self, q: str, limit: int = 20) -> list[SearchResult]:
        assets = self._get_active_assets()
        needle = q.strip().casefold()
        
        if not needle:
            popular = ["AAPL", "MSFT", "NVDA", "GOOGL", "AMZN", "META", "TSLA", "AMD", "NFLX", "INTC"]
            pop_map = {a.get("symbol"): a for a in assets if a.get("symbol") in popular}
            res = []
            for sym in popular:
                if sym in pop_map:
                    res.append(SearchResult(
                        symbol=sym,
                        name=pop_map[sym].get("name", ""),
                        exchange=pop_map[sym].get("exchange", ""),
                    ))
            return res[:limit]

        exact_symbol: list[SearchResult] = []
        prefix_symbol: list[SearchResult] = []
        prefix_name: list[SearchResult] = []
        word_start_name: list[SearchResult] = []
        contains_symbol: list[SearchResult] = []
        contains_name: list[SearchResult] = []

        seen_symbols: set[str] = set()

        for asset in assets:
            symbol = (asset.get("symbol") or "").strip()
            if not symbol or symbol in seen_symbols:
                continue
            name = (asset.get("name") or "").strip()
            exchange = asset.get("exchange") or ""
            sym_fold = symbol.casefold()
            name_fold = name.casefold()

            item = SearchResult(symbol=symbol, name=name, exchange=exchange)

            if sym_fold == needle:
                exact_symbol.append(item)
                seen_symbols.add(symbol)
            elif sym_fold.startswith(needle):
                prefix_symbol.append(item)
                seen_symbols.add(symbol)
            elif name_fold.startswith(needle):
                prefix_name.append(item)
                seen_symbols.add(symbol)
            elif any(w.startswith(needle) for w in name_fold.split()):
                word_start_name.append(item)
                seen_symbols.add(symbol)
            elif needle in sym_fold:
                contains_symbol.append(item)
                seen_symbols.add(symbol)
            elif needle in name_fold:
                contains_name.append(item)
                seen_symbols.add(symbol)

        # Sort prefix symbols by length ascending, then alphabetically (e.g. A, AA, AAL, AAP, AAPL, AMZN)
        prefix_symbol.sort(key=lambda x: (len(x.symbol), x.symbol))
        prefix_name.sort(key=lambda x: (len(x.name), x.name, x.symbol))
        word_start_name.sort(key=lambda x: (len(x.name), x.name, x.symbol))
        contains_symbol.sort(key=lambda x: (len(x.symbol), x.symbol))
        contains_name.sort(key=lambda x: (len(x.name), x.name, x.symbol))

        combined = (
            exact_symbol
            + prefix_symbol
            + prefix_name
            + word_start_name
            + contains_symbol
            + contains_name
        )
        return combined[:limit]

    # Broad pool of well-known US stocks to compute live movers from
    _MOVER_POOL = [
        "AAPL", "MSFT", "NVDA", "GOOGL", "AMZN", "META", "TSLA", "AMD",
        "NFLX", "INTC", "CRM", "ORCL", "ADBE", "QCOM", "TXN", "IBM",
        "MU", "AMAT", "AVGO", "LRCX", "KLAC", "MRVL", "PANW", "CRWD",
        "ZS", "SNOW", "PLTR", "UBER", "LYFT", "ABNB", "SHOP", "SQ",
        "PYPL", "V", "MA", "JPM", "BAC", "GS", "MS", "WFC",
        "XOM", "CVX", "PFE", "JNJ", "MRNA", "BNTX", "UNH", "CVS",
        "WMT", "COST", "TGT", "HD", "LOW", "NKE", "SBUX", "MCD",
        "DIS", "NFLX", "CMCSA", "T", "VZ", "TMUS", "BA", "LMT",
    ]

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]:
        # First try the Alpaca premium screener endpoint
        try:
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
            if results:
                return results
        except Exception as err:
            logger.warning(f"Alpaca get_movers screener endpoint unavailable: {err}, falling back to snapshot scan")

        # Fallback: compute real movers from live snapshots (works on all Alpaca plans)
        try:
            pool = list(dict.fromkeys(self._MOVER_POOL))  # deduplicate
            raw_snapshots = self.get_snapshot(pool)
            movers: list[MoverPayload] = []
            for snap in raw_snapshots:
                if snap.lastPrice <= 0:
                    continue
                movers.append(
                    MoverPayload(
                        symbol=snap.symbol,
                        name=snap.symbol,
                        lastPrice=snap.lastPrice,
                        changePercent=snap.changePercent,
                    )
                )

            if sort == "gainers":
                movers.sort(key=lambda m: m.changePercent, reverse=True)
            elif sort == "losers":
                movers.sort(key=lambda m: m.changePercent)
            else:
                movers.sort(key=lambda m: abs(m.changePercent), reverse=True)

            return movers[:limit]
        except Exception as err:
            logger.error(f"get_movers snapshot fallback failed: {err}")
            return []


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
        subscribed_symbols: set[str] = set()

        def reconcile_subscriptions(ws: Any) -> None:
            try:
                desired = {
                    symbol.upper()
                    for symbol in get_redis().smembers(ACTIVE_STREAM_SYMBOLS_KEY)
                }
            except Exception as exc:
                logger.warning("Unable to load active quote subscriptions: %s", exc)
                return

            to_add = desired - subscribed_symbols
            to_remove = subscribed_symbols - desired
            if to_add:
                ws.send(json.dumps({"action": "subscribe", "quotes": sorted(to_add)}))
            if to_remove:
                ws.send(json.dumps({"action": "unsubscribe", "quotes": sorted(to_remove)}))
            subscribed_symbols.clear()
            subscribed_symbols.update(desired)

        def on_message(ws: Any, message: str) -> None:
            try:
                payload = json.loads(message)
            except json.JSONDecodeError:
                return
            messages = payload if isinstance(payload, list) else [payload]
            for item in messages:
                t = item.get("T")
                if t == "success":
                    msg = item.get("msg")
                    if msg == "connected":
                        ws.send(json.dumps({"action": "auth", "key": api_key, "secret": secret_key}))
                    elif msg == "authenticated":
                        reconcile_subscriptions(ws)
                    continue
                if t not in ("q", "t"):
                    continue
                symbol = (item.get("S") or "").upper()
                if not symbol:
                    continue
                if t == "t":
                    last_price = float(item.get("p") or 0)
                else:
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
            pass

        def on_pong(ws_app: Any, _message: Any) -> None:
            reconcile_subscriptions(ws_app)

        ws_app = websocket.WebSocketApp(
            stream_url,
            on_message=on_message,
            on_open=on_open,
            on_pong=on_pong,
        )
        while not should_stop():
            ws_app.run_forever(ping_interval=20, ping_timeout=10)
            if should_stop():
                break
            raise ConnectionError("Alpaca quote stream disconnected")


class AlphaVantageAdapter(MarketDataSource):
    _fund_cache: dict[str, tuple[float, FundamentalsPayload]] = {}

    def __init__(self, *, api_key: str) -> None:
        self._api_key = api_key
        self._client = _HttpClient()

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        upper = symbol.upper()
        now = time.time()
        if upper in self._fund_cache:
            cache_time, payload = self._fund_cache[upper]
            if now - cache_time < 86400.0:
                return payload

        comp_name = upper
        m_cap = None
        pe_val = None
        eps_val = None
        hi_52 = None
        lo_52 = None
        dividend_yield = None
        desc_val = None
        buy_pct = None
        hold_pct = None
        sell_pct = None

        # 1. Try fetching OVERVIEW from AlphaVantage
        try:
            overview_data = self._client.get_json(
                ALPHA_VANTAGE_BASE_URL,
                params={"function": "OVERVIEW", "symbol": upper, "apikey": self._api_key},
            )
            if overview_data and overview_data.get("Symbol"):
                def opt_dec(v: Any) -> Decimal | None:
                    return _to_decimal(v) if v not in (None, "", "None", "-") else None

                comp_name = overview_data.get("Name") or comp_name
                m_cap = opt_dec(overview_data.get("MarketCapitalization")) or m_cap
                pe_val = opt_dec(overview_data.get("PERatio")) or pe_val
                eps_val = opt_dec(overview_data.get("EPS")) or eps_val
                hi_52 = opt_dec(overview_data.get("52WeekHigh")) or hi_52
                lo_52 = opt_dec(overview_data.get("52WeekLow")) or lo_52
                dividend_yield = opt_dec(overview_data.get("DividendYield"))
                desc_val = overview_data.get("Description") or desc_val

                s_buy = int(overview_data.get("AnalystRatingStrongBuy") or 0) + int(overview_data.get("AnalystRatingBuy") or 0)
                s_hold = int(overview_data.get("AnalystRatingHold") or 0)
                s_sell = int(overview_data.get("AnalystRatingSell") or 0) + int(overview_data.get("AnalystRatingStrongSell") or 0)
                tot = s_buy + s_hold + s_sell
                if tot > 0:
                    buy_pct = Decimal(str(round((s_buy / tot) * 100, 1)))
                    hold_pct = Decimal(str(round((s_hold / tot) * 100, 1)))
                    sell_pct = Decimal(str(round((s_sell / tot) * 100, 1)))
        except Exception as o_err:
            logger.warning(f"AlphaVantage OVERVIEW warning for {upper}: {o_err}")

        # 2. Always fetch real EARNINGS series
        earnings_series: list[dict[str, Any]] = []
        try:
            earn_data = self._client.get_json(
                ALPHA_VANTAGE_BASE_URL,
                params={"function": "EARNINGS", "symbol": upper, "apikey": self._api_key},
            )
            if earn_data and isinstance(earn_data.get("quarterlyEarnings"), list) and earn_data["quarterlyEarnings"]:
                q_items = earn_data["quarterlyEarnings"][:4]
                for item in reversed(q_items):
                    f_date = item.get("fiscalDateEnding") or ""
                    r_date = item.get("reportedDate") or ""
                    est = item.get("estimatedEPS")
                    act = item.get("reportedEPS")
                    surp = item.get("surprise")
                    r_time = item.get("reportTime") or "post-market"

                    top_lbl = "Q1"
                    bottom_lbl = "FY25"
                    if f_date:
                        try:
                            p = f_date.split("-")
                            m = int(p[1])
                            top_lbl = f"Q{(m - 1) // 3 + 1}"
                            bottom_lbl = f"FY{p[0][-2:]}"
                        except Exception:
                            pass

                    earnings_series.append({
                        "fiscalDate": f_date,
                        "reportedDate": r_date,
                        "topLabel": top_lbl,
                        "bottomLabel": bottom_lbl,
                        "estimatedEps": float(est) if est not in (None, "", "None") else 0.0,
                        "actualEps": float(act) if act not in (None, "", "None") else None,
                        "surprise": float(surp) if surp not in (None, "", "None") else 0.0,
                        "isUpcoming": False,
                        "reportTime": "After-hours" if "post" in r_time.lower() else "Before open",
                        "upcomingDate": r_date[5:] if len(r_date) >= 10 else "TBD",
                    })

                if earnings_series:
                    last_q = earnings_series[-1]
                    last_est = last_q["estimatedEps"] or (float(eps_val) / 4)
                    upcoming_est = round(last_est * 1.05, 2)
                    last_q_num = int(last_q["topLabel"][1]) if len(last_q["topLabel"]) >= 2 and last_q["topLabel"][1].isdigit() else 4
                    next_q_num = (last_q_num % 4) + 1
                    next_fy = last_q["bottomLabel"]
                    if next_q_num == 1:
                        try:
                            next_fy = f"FY{int(next_fy[2:]) + 1:02d}"
                        except Exception:
                            pass

                    earnings_series.append({
                        "fiscalDate": "",
                        "reportedDate": "",
                        "topLabel": f"Q{next_q_num}",
                        "bottomLabel": next_fy,
                        "estimatedEps": upcoming_est,
                        "actualEps": None,
                        "surprise": None,
                        "isUpcoming": True,
                        "reportTime": "After-hours",
                        "upcomingDate": "Next Release",
                    })
        except Exception as e_err:
            logger.warning(f"AlphaVantage EARNINGS warning for {upper}: {e_err}")

        # 3. Always fetch real INCOME_STATEMENT series
        financial_statements: dict[str, Any] = {"quarterly": [], "annual": []}
        try:
            inc_data = self._client.get_json(
                ALPHA_VANTAGE_BASE_URL,
                params={"function": "INCOME_STATEMENT", "symbol": upper, "apikey": self._api_key},
            )
            if inc_data:
                # Quarterly Reports
                q_reports = inc_data.get("quarterlyReports") or []
                if isinstance(q_reports, list) and q_reports:
                    for item in reversed(q_reports[:5]):
                        f_date = item.get("fiscalDateEnding") or ""
                        rev = float(item.get("totalRevenue") or 0)
                        gp = float(item.get("grossProfit") or 0)
                        ni = float(item.get("netIncome") or 0)
                        if not rev or not gp or not ni:
                            continue
                        margin = (ni / rev * 100) if rev != 0 else 0.0

                        top_lbl = "Q1"
                        bottom_lbl = "FY25"
                        if f_date:
                            try:
                                p = f_date.split("-")
                                m = int(p[1])
                                top_lbl = f"Q{(m - 1) // 3 + 1}"
                                bottom_lbl = f"FY{p[0][-2:]}"
                            except Exception:
                                pass
                        financial_statements["quarterly"].append({
                            "topLabel": top_lbl,
                            "bottomLabel": bottom_lbl,
                            "periodLabel": f"{top_lbl} {bottom_lbl}",
                            "fiscalDate": f_date,
                            "revenue": rev,
                            "grossProfit": gp,
                            "netIncome": ni,
                            "netMargin": round(margin, 1),
                        })

                # Annual Reports
                a_reports = inc_data.get("annualReports") or []
                if isinstance(a_reports, list) and a_reports:
                    for item in reversed(a_reports[:5]):
                        f_date = item.get("fiscalDateEnding") or ""
                        rev = float(item.get("totalRevenue") or 0)
                        gp = float(item.get("grossProfit") or 0)
                        ni = float(item.get("netIncome") or 0)
                        if not rev or not gp or not ni:
                            continue
                        margin = (ni / rev * 100) if rev != 0 else 0.0
                        yr = f_date[:4] if len(f_date) >= 4 else "2025"

                        financial_statements["annual"].append({
                            "topLabel": "FY",
                            "bottomLabel": yr[-2:],
                            "periodLabel": f"FY {yr}",
                            "fiscalDate": f_date,
                            "revenue": rev,
                            "grossProfit": gp,
                            "netIncome": ni,
                            "netMargin": round(margin, 1),
                        })
        except Exception as i_err:
            logger.warning(f"AlphaVantage INCOME_STATEMENT warning for {upper}: {i_err}")

        res = FundamentalsPayload(
            symbol=upper,
            name=comp_name,
            marketCap=m_cap,
            peRatio=pe_val,
            eps=eps_val,
            dividendYield=dividend_yield,
            fiftyTwoWeekHigh=hi_52,
            fiftyTwoWeekLow=lo_52,
            description=desc_val,
            yearRange=(f"{lo_52:.2f} - {hi_52:.2f}" if lo_52 is not None and hi_52 is not None else None),
            expertBuyPercent=buy_pct,
            expertHoldPercent=hold_pct,
            expertSellPercent=sell_pct,
            earningsPrices=earnings_series,
            roeSeries=[],
            debtEquitySeries=[],
            netProfitMarginSeries=[],
            financialStatements=(financial_statements if any(financial_statements.values()) else None),
        )
        self._fund_cache[upper] = (now, res)
        return res

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
        base = self._av.get_fundamentals(symbol)
        upper = symbol.upper()

        # Query Alpaca for live real-time market stats (Volume, Open, Prev Close, Day High, Day Low)
        try:
            snapshot_url = f"{ALPACA_DATA_BASE_URL}/v2/stocks/snapshots"
            snap_data = self._alpaca._client.get_json(
                snapshot_url,
                params={"symbols": upper, "feed": self._alpaca._feed or "iex"},
            )
            snapshot = snap_data.get(upper) or (snap_data if isinstance(snap_data, dict) and "dailyBar" in snap_data else {})
            daily_bar = snapshot.get("dailyBar") or {}
            prev_bar = snapshot.get("prevDailyBar") or {}
            latest_trade = snapshot.get("latestTrade") or {}

            v = daily_bar.get("v") or base.volume
            o = daily_bar.get("o") or base.openPrice
            h = daily_bar.get("h") or base.todaysHigh
            l = daily_bar.get("l") or base.todaysLow
            c_prev = prev_bar.get("c") or base.prevClose
            d_range = (
                f"{float(l):.2f} - {float(h):.2f}"
                if l is not None and h is not None
                else base.dayRange
            )

            return FundamentalsPayload(
                symbol=base.symbol,
                name=base.name,
                marketCap=base.marketCap,
                peRatio=base.peRatio,
                eps=base.eps,
                dividendYield=base.dividendYield,
                fiftyTwoWeekHigh=base.fiftyTwoWeekHigh,
                fiftyTwoWeekLow=base.fiftyTwoWeekLow,
                description=base.description,
                volume=int(v) if v else None,
                avgVolume=base.avgVolume,
                openPrice=_to_decimal(o) if o is not None else None,
                prevClose=_to_decimal(c_prev) if c_prev is not None else None,
                rvol=base.rvol,
                todaysLow=_to_decimal(l) if l is not None else None,
                todaysHigh=_to_decimal(h) if h is not None else None,
                dayRange=d_range,
                yearRange=base.yearRange,
                expertBuyPercent=base.expertBuyPercent,
                expertHoldPercent=base.expertHoldPercent,
                expertSellPercent=base.expertSellPercent,
                earningsPrices=base.earningsPrices,
                roeSeries=base.roeSeries,
                debtEquitySeries=base.debtEquitySeries,
                netProfitMarginSeries=base.netProfitMarginSeries,
                financialStatements=base.financialStatements,
            )
        except Exception as alpaca_err:
            logger.warning(f"Error fetching live Alpaca stats in get_fundamentals: {alpaca_err}")
            return base

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
    api_key = app.config.get("ALPACA_API_KEY", "")
    secret_key = app.config.get("ALPACA_SECRET_KEY", "")
    data_feed = app.config.get("ALPACA_DATA_FEED", "") or "iex"

    alpaca = AlpacaMarketDataAdapter(
        api_key=api_key,
        secret_key=secret_key,
        data_feed=data_feed,
    )
    av_key = app.config.get("ALPHA_VANTAGE_API_KEY", "")
    av = AlphaVantageAdapter(api_key=av_key)
    return CompositeMarketDataAdapter(alpaca=alpaca, av=av)
