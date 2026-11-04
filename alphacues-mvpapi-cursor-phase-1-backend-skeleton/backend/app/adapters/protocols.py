from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol


class EmailSender(Protocol):
    def send_otp(self, to_email: str, otp_code: str) -> None: ...


@dataclass(frozen=True)
class QuotePayload:
    symbol: str
    lastPrice: Decimal
    changeAmount: Decimal
    changePercent: Decimal
    asOf: str


@dataclass(frozen=True)
class BarItem:
    timeStamp: str
    openPrice: Decimal
    highPrice: Decimal
    lowPrice: Decimal
    closePrice: Decimal
    volume: int


@dataclass(frozen=True)
class BarsPayload:
    symbol: str
    bars: list[BarItem]


@dataclass(frozen=True)
class SnapshotPayload:
    symbol: str
    lastPrice: Decimal
    changeAmount: Decimal
    changePercent: Decimal
    asOf: str


@dataclass(frozen=True)
class SearchResult:
    symbol: str
    name: str
    exchange: str


@dataclass(frozen=True)
class MoverPayload:
    symbol: str
    name: str
    lastPrice: Decimal
    changePercent: Decimal


@dataclass(frozen=True)
class FundamentalsPayload:
    symbol: str
    name: str
    marketCap: Decimal | None
    peRatio: Decimal | None
    eps: Decimal | None
    dividendYield: Decimal | None
    fiftyTwoWeekHigh: Decimal | None
    fiftyTwoWeekLow: Decimal | None
    description: str | None
    volume: int | None = None
    avgVolume: str | None = None
    openPrice: Decimal | None = None
    prevClose: Decimal | None = None
    rvol: Decimal | None = None
    todaysLow: Decimal | None = None
    todaysHigh: Decimal | None = None
    dayRange: str | None = None
    yearRange: str | None = None
    expertBuyPercent: Decimal | None = None
    expertHoldPercent: Decimal | None = None
    expertSellPercent: Decimal | None = None
    # Financial Overview Chart Series
    earningsPrices: list[dict[str, Any]] | None = None
    roeSeries: list[dict[str, Any]] | None = None
    debtEquitySeries: list[dict[str, Any]] | None = None
    netProfitMarginSeries: list[dict[str, Any]] | None = None
    financialStatements: dict[str, Any] | None = None


VALID_TIMEFRAMES = frozenset(
    {"5min", "15min", "30min", "1hour", "1day", "1week", "1month"}
)
VALID_RANGES = frozenset({"1D", "5D", "1W", "1M", "3M", "YTD", "6M", "1Y", "5Y", "MAX"})


class MarketDataSource(Protocol):
    def get_quote(self, symbol: str) -> QuotePayload: ...

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload: ...

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]: ...

    def search(self, q: str, limit: int = 10) -> list[SearchResult]: ...

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]: ...

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload: ...
