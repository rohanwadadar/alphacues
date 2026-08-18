from __future__ import annotations

from collections.abc import Callable
from decimal import Decimal
import time

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

_FIXTURE_SYMBOLS = ("AAPL", "MSFT", "GOOGL", "TSLA")

_QUOTES: dict[str, QuotePayload] = {
    "AAPL": QuotePayload(
        symbol="AAPL",
        lastPrice=Decimal("188.900000"),
        changeAmount=Decimal("1.240000"),
        changePercent=Decimal("0.661200"),
        asOf="2026-05-13T14:30:01Z",
    ),
    "MSFT": QuotePayload(
        symbol="MSFT",
        lastPrice=Decimal("415.500000"),
        changeAmount=Decimal("-2.100000"),
        changePercent=Decimal("-0.502900"),
        asOf="2026-05-13T14:30:01Z",
    ),
    "GOOGL": QuotePayload(
        symbol="GOOGL",
        lastPrice=Decimal("175.320000"),
        changeAmount=Decimal("3.450000"),
        changePercent=Decimal("2.005800"),
        asOf="2026-05-13T14:30:01Z",
    ),
    "TSLA": QuotePayload(
        symbol="TSLA",
        lastPrice=Decimal("178.250000"),
        changeAmount=Decimal("-4.750000"),
        changePercent=Decimal("-2.594600"),
        asOf="2026-05-13T14:30:01Z",
    ),
}

_NAMES: dict[str, str] = {
    "AAPL": "Apple Inc.",
    "MSFT": "Microsoft Corporation",
    "GOOGL": "Alphabet Inc. Class A",
    "TSLA": "Tesla, Inc.",
}

_EXCHANGES: dict[str, str] = {
    "AAPL": "NASDAQ",
    "MSFT": "NASDAQ",
    "GOOGL": "NASDAQ",
    "TSLA": "NASDAQ",
}

_BARS: dict[str, list[BarItem]] = {
    "AAPL": [
        BarItem(
            timeStamp="2026-05-13T14:30:00Z",
            openPrice=Decimal("187.500000"),
            highPrice=Decimal("189.200000"),
            lowPrice=Decimal("187.100000"),
            closePrice=Decimal("188.900000"),
            volume=1_200_000,
        ),
        BarItem(
            timeStamp="2026-05-12T14:30:00Z",
            openPrice=Decimal("186.500000"),
            highPrice=Decimal("188.200000"),
            lowPrice=Decimal("186.100000"),
            closePrice=Decimal("187.800000"),
            volume=1_540_000,
        ),
        BarItem(
            timeStamp="2026-05-11T14:30:00Z",
            openPrice=Decimal("185.900000"),
            highPrice=Decimal("187.400000"),
            lowPrice=Decimal("185.500000"),
            closePrice=Decimal("186.660000"),
            volume=1_320_000,
        ),
        BarItem(
            timeStamp="2026-05-10T14:30:00Z",
            openPrice=Decimal("184.800000"),
            highPrice=Decimal("186.300000"),
            lowPrice=Decimal("184.200000"),
            closePrice=Decimal("185.750000"),
            volume=1_100_000,
        ),
        BarItem(
            timeStamp="2026-05-09T14:30:00Z",
            openPrice=Decimal("183.600000"),
            highPrice=Decimal("185.100000"),
            lowPrice=Decimal("183.100000"),
            closePrice=Decimal("184.500000"),
            volume=980_000,
        ),
    ],
    "MSFT": [
        BarItem(
            timeStamp="2026-05-13T14:30:00Z",
            openPrice=Decimal("417.000000"),
            highPrice=Decimal("418.500000"),
            lowPrice=Decimal("414.800000"),
            closePrice=Decimal("415.500000"),
            volume=890_000,
        ),
        BarItem(
            timeStamp="2026-05-12T14:30:00Z",
            openPrice=Decimal("418.200000"),
            highPrice=Decimal("419.800000"),
            lowPrice=Decimal("416.500000"),
            closePrice=Decimal("417.600000"),
            volume=920_000,
        ),
        BarItem(
            timeStamp="2026-05-11T14:30:00Z",
            openPrice=Decimal("416.000000"),
            highPrice=Decimal("418.900000"),
            lowPrice=Decimal("415.200000"),
            closePrice=Decimal("418.100000"),
            volume=850_000,
        ),
        BarItem(
            timeStamp="2026-05-10T14:30:00Z",
            openPrice=Decimal("414.500000"),
            highPrice=Decimal("417.200000"),
            lowPrice=Decimal("413.800000"),
            closePrice=Decimal("416.300000"),
            volume=810_000,
        ),
        BarItem(
            timeStamp="2026-05-09T14:30:00Z",
            openPrice=Decimal("412.900000"),
            highPrice=Decimal("415.600000"),
            lowPrice=Decimal("411.500000"),
            closePrice=Decimal("414.000000"),
            volume=760_000,
        ),
    ],
    "GOOGL": [
        BarItem(
            timeStamp="2026-05-13T14:30:00Z",
            openPrice=Decimal("172.100000"),
            highPrice=Decimal("176.000000"),
            lowPrice=Decimal("171.800000"),
            closePrice=Decimal("175.320000"),
            volume=1_050_000,
        ),
        BarItem(
            timeStamp="2026-05-12T14:30:00Z",
            openPrice=Decimal("170.500000"),
            highPrice=Decimal("173.200000"),
            lowPrice=Decimal("170.100000"),
            closePrice=Decimal("171.870000"),
            volume=990_000,
        ),
        BarItem(
            timeStamp="2026-05-11T14:30:00Z",
            openPrice=Decimal("169.800000"),
            highPrice=Decimal("171.500000"),
            lowPrice=Decimal("169.200000"),
            closePrice=Decimal("170.900000"),
            volume=870_000,
        ),
        BarItem(
            timeStamp="2026-05-10T14:30:00Z",
            openPrice=Decimal("168.400000"),
            highPrice=Decimal("170.200000"),
            lowPrice=Decimal("167.900000"),
            closePrice=Decimal("169.500000"),
            volume=820_000,
        ),
        BarItem(
            timeStamp="2026-05-09T14:30:00Z",
            openPrice=Decimal("167.200000"),
            highPrice=Decimal("169.000000"),
            lowPrice=Decimal("166.800000"),
            closePrice=Decimal("168.300000"),
            volume=790_000,
        ),
    ],
    "TSLA": [
        BarItem(
            timeStamp="2026-05-13T14:30:00Z",
            openPrice=Decimal("182.000000"),
            highPrice=Decimal("183.500000"),
            lowPrice=Decimal("177.500000"),
            closePrice=Decimal("178.250000"),
            volume=2_100_000,
        ),
        BarItem(
            timeStamp="2026-05-12T14:30:00Z",
            openPrice=Decimal("184.500000"),
            highPrice=Decimal("186.000000"),
            lowPrice=Decimal("181.200000"),
            closePrice=Decimal("183.000000"),
            volume=1_950_000,
        ),
        BarItem(
            timeStamp="2026-05-11T14:30:00Z",
            openPrice=Decimal("185.800000"),
            highPrice=Decimal("187.400000"),
            lowPrice=Decimal("183.600000"),
            closePrice=Decimal("184.900000"),
            volume=1_800_000,
        ),
        BarItem(
            timeStamp="2026-05-10T14:30:00Z",
            openPrice=Decimal("187.200000"),
            highPrice=Decimal("188.900000"),
            lowPrice=Decimal("185.000000"),
            closePrice=Decimal("186.400000"),
            volume=1_700_000,
        ),
        BarItem(
            timeStamp="2026-05-09T14:30:00Z",
            openPrice=Decimal("188.500000"),
            highPrice=Decimal("190.100000"),
            lowPrice=Decimal("186.800000"),
            closePrice=Decimal("187.600000"),
            volume=1_650_000,
        ),
    ],
}

_FUNDAMENTALS: dict[str, FundamentalsPayload] = {
    "AAPL": FundamentalsPayload(
        symbol="AAPL",
        name="Apple Inc.",
        marketCap=Decimal("2900000000000.000000"),
        peRatio=Decimal("29.500000"),
        eps=Decimal("6.410000"),
        dividendYield=Decimal("0.520000"),
        fiftyTwoWeekHigh=Decimal("199.620000"),
        fiftyTwoWeekLow=Decimal("164.080000"),
        description="Apple Inc. designs, manufactures, and markets smartphones and computers.",
    ),
    "MSFT": FundamentalsPayload(
        symbol="MSFT",
        name="Microsoft Corporation",
        marketCap=Decimal("3100000000000.000000"),
        peRatio=Decimal("35.200000"),
        eps=Decimal("11.800000"),
        dividendYield=Decimal("0.720000"),
        fiftyTwoWeekHigh=Decimal("430.820000"),
        fiftyTwoWeekLow=Decimal("362.900000"),
        description="Microsoft Corporation develops and licenses software and cloud services.",
    ),
    "GOOGL": FundamentalsPayload(
        symbol="GOOGL",
        name="Alphabet Inc. Class A",
        marketCap=Decimal("2200000000000.000000"),
        peRatio=Decimal("26.100000"),
        eps=Decimal("6.720000"),
        dividendYield=None,
        fiftyTwoWeekHigh=Decimal("191.750000"),
        fiftyTwoWeekLow=Decimal("140.530000"),
        description="Alphabet Inc. provides online advertising and cloud computing services.",
    ),
}


class FakeMarketDataAdapter(MarketDataSource):
    def get_quote(self, symbol: str) -> QuotePayload:
        upper = symbol.upper()
        if upper in _QUOTES:
            return _QUOTES[upper]
        return QuotePayload(
            symbol=upper,
            lastPrice=Decimal("100.000000"),
            changeAmount=Decimal("0.000000"),
            changePercent=Decimal("0.000000"),
            asOf="2026-05-13T14:30:01Z",
        )

    def get_bars(self, symbol: str, timeframe: str, range: str) -> BarsPayload:
        upper = symbol.upper()
        base_bars = _BARS.get(upper, _BARS["AAPL"])
        if not base_bars:
            return BarsPayload(symbol=upper, bars=[])

        count_map = {
            "1D": 5,
            "1W": 10,
            "1M": 30,
            "3M": 90,
            "6M": 180,
            "1Y": 365,
            "5Y": 500,
            "MAX": 700,
        }
        count = count_map.get(range, 5)
        if count <= len(base_bars):
            return BarsPayload(symbol=upper, bars=base_bars[:count])

        # Synthesize multi-period historical bar series with realistic price trend
        from datetime import datetime, timedelta, timezone
        last_price = base_bars[0].closePrice
        start_dt = datetime.now(timezone.utc)
        synthetic_bars: list[BarItem] = []

        import math
        for i in range(count):
            dt = start_dt - timedelta(days=i)
            wave = math.sin(i * 0.2) * float(last_price) * 0.03
            c_price = Decimal(str(round(float(last_price) + wave - (i * 0.05), 2)))
            h_price = c_price + Decimal("1.50")
            l_price = max(Decimal("1.00"), c_price - Decimal("1.50"))
            o_price = c_price - Decimal("0.30")
            vol = 1_000_000 + (i * 10_000)

            synthetic_bars.append(
                BarItem(
                    timeStamp=dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    openPrice=o_price,
                    highPrice=h_price,
                    lowPrice=l_price,
                    closePrice=c_price,
                    volume=vol,
                )
            )

        return BarsPayload(symbol=upper, bars=synthetic_bars)

    def get_snapshot(self, symbols: list[str]) -> list[SnapshotPayload]:
        results: list[SnapshotPayload] = []
        for symbol in symbols:
            upper = symbol.upper()
            quote = _QUOTES.get(upper)
            if quote is None:
                continue
            results.append(
                SnapshotPayload(
                    symbol=quote.symbol,
                    lastPrice=quote.lastPrice,
                    changeAmount=quote.changeAmount,
                    changePercent=quote.changePercent,
                    asOf=quote.asOf,
                )
            )
        return results

    def search(self, q: str, limit: int = 10) -> list[SearchResult]:
        needle = q.casefold()
        matches: list[SearchResult] = []
        for symbol in _FIXTURE_SYMBOLS:
            name = _NAMES[symbol]
            if needle in symbol.casefold() or needle in name.casefold():
                matches.append(
                    SearchResult(
                        symbol=symbol,
                        name=name,
                        exchange=_EXCHANGES[symbol],
                    )
                )
        return matches[:limit]

    def get_movers(self, sort: str = "gainers", limit: int = 10) -> list[MoverPayload]:
        movers = [
            MoverPayload(
                symbol="GOOGL",
                name=_NAMES["GOOGL"],
                lastPrice=_QUOTES["GOOGL"].lastPrice,
                changePercent=_QUOTES["GOOGL"].changePercent,
            ),
            MoverPayload(
                symbol="AAPL",
                name=_NAMES["AAPL"],
                lastPrice=_QUOTES["AAPL"].lastPrice,
                changePercent=_QUOTES["AAPL"].changePercent,
            ),
            MoverPayload(
                symbol="TSLA",
                name=_NAMES["TSLA"],
                lastPrice=_QUOTES["TSLA"].lastPrice,
                changePercent=_QUOTES["TSLA"].changePercent,
            ),
            MoverPayload(
                symbol="MSFT",
                name=_NAMES["MSFT"],
                lastPrice=_QUOTES["MSFT"].lastPrice,
                changePercent=_QUOTES["MSFT"].changePercent,
            ),
        ]
        if sort == "gainers":
            sorted_movers = sorted(movers, key=lambda m: m.changePercent, reverse=True)
        elif sort == "losers":
            sorted_movers = sorted(movers, key=lambda m: m.changePercent)
        else:
            sorted_movers = movers
        return sorted_movers[:limit]

    def get_fundamentals(self, symbol: str) -> FundamentalsPayload:
        upper = symbol.upper()
        if upper in _FUNDAMENTALS:
            return _FUNDAMENTALS[upper]
        return FundamentalsPayload(
            symbol=upper,
            name=f"{upper} Corp",
            marketCap=Decimal("1000000000.000000"),
            peRatio=None,
            eps=None,
            dividendYield=None,
            fiftyTwoWeekHigh=Decimal("150.000000"),
            fiftyTwoWeekLow=Decimal("100.000000"),
            description=None,
        )


    def stream_quotes(
        self,
        *,
        stream_url: str,
        on_quote: Callable[[QuotePayload], None],
        should_stop: Callable[[], bool],
    ) -> None:
        del stream_url
        while not should_stop():
            for symbol in _FIXTURE_SYMBOLS:
                if should_stop():
                    return
                quote = self.get_quote(symbol)
                on_quote(quote)
            time.sleep(1)
