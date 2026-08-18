from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, Numeric, Text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Mapped, Session, mapped_column

from app.adapters.protocols import BarsPayload, QuotePayload
from app.shared.db import db


def _parse_timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


class StockTick(db.Model):
    __tablename__ = "stock_tick"

    symbol: Mapped[str] = mapped_column(Text, primary_key=True)
    time_stamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), primary_key=True
    )
    open_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    high_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    low_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    close_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    volume: Mapped[int] = mapped_column(BigInteger, nullable=False)

    @classmethod
    def upsert_bars(cls, session: Session, bars_payload: BarsPayload) -> None:
        for bar in bars_payload.bars:
            stmt = (
                insert(cls)
                .values(
                    symbol=bars_payload.symbol,
                    time_stamp=_parse_timestamp(bar.timeStamp),
                    open_price=bar.openPrice,
                    high_price=bar.highPrice,
                    low_price=bar.lowPrice,
                    close_price=bar.closePrice,
                    volume=bar.volume,
                )
                .on_conflict_do_update(
                    index_elements=["symbol", "time_stamp"],
                    set_={
                        "open_price": bar.openPrice,
                        "high_price": bar.highPrice,
                        "low_price": bar.lowPrice,
                        "close_price": bar.closePrice,
                        "volume": bar.volume,
                    },
                )
            )
            session.execute(stmt)
        session.flush()
    @classmethod
    def upsert_tick(cls, session: Session, quote: QuotePayload) -> None:
        price = quote.lastPrice
        stmt = (
            insert(cls)
            .values(
                symbol=quote.symbol,
                time_stamp=_parse_timestamp(quote.asOf),
                open_price=price,
                high_price=price,
                low_price=price,
                close_price=price,
                volume=0,
            )
            .on_conflict_do_update(
                index_elements=["symbol", "time_stamp"],
                set_={
                    "open_price": price,
                    "high_price": price,
                    "low_price": price,
                    "close_price": price,
                },
            )
        )
        session.execute(stmt)
        session.flush()
