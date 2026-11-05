from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    PrimaryKeyConstraint,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.db import db

PORTFOLIO_ACTIONS = ("BUY", "SELL")


class PortfolioEvent(db.Model):
    __tablename__ = "portfolio_event"

    event_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    time_stamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    symbol: Mapped[str] = mapped_column(Text, nullable=False)
    action: Mapped[str] = mapped_column(Text, nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    volume: Mapped[int] = mapped_column(Integer, nullable=False)
    watchlist_name: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        CheckConstraint(
            "action IN ('BUY','SELL')",
            name="ck_portfolio_event_action",
        ),
        CheckConstraint(
            "price > 0",
            name="ck_portfolio_event_price_positive",
        ),
        CheckConstraint(
            "volume > 0",
            name="ck_portfolio_event_volume_positive",
        ),
        Index("idx_portfolio_event_user_time", "user_id", "time_stamp"),
    )


class Position(db.Model):
    __tablename__ = "positions"

    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    symbol: Mapped[str] = mapped_column(Text, nullable=False)
    volume: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    total_price: Mapped[Decimal] = mapped_column(
        Numeric(18, 6), nullable=False, default=Decimal("0"), server_default="0"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        PrimaryKeyConstraint("user_id", "symbol"),
        Index("idx_positions_user", "user_id"),
    )


class PortfolioSnapshot(db.Model):
    __tablename__ = "portfolio_snapshot"

    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    time_stamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    symbol: Mapped[str] = mapped_column(Text, nullable=False)
    quantity: Mapped[int] = mapped_column(BigInteger, nullable=False)
    total_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)

    __table_args__ = (PrimaryKeyConstraint("user_id", "time_stamp", "symbol"),)
