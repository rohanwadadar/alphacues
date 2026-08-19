from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.shared.db import db


class Watchlist(db.Model):
    __tablename__ = "watchlists"

    watchlist_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), ForeignKey("users.user_id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    items: Mapped[list[WatchlistItem]] = relationship(
        back_populates="watchlist",
        cascade="all, delete-orphan",
        order_by="WatchlistItem.added_at",
    )

    __table_args__ = (Index("idx_watchlist_user", "user_id"),)


class WatchlistItem(db.Model):
    __tablename__ = "watchlist_items"

    id: Mapped[int] = mapped_column(BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True)
    watchlist_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), ForeignKey("watchlists.watchlist_id"), nullable=False
    )
    symbol: Mapped[str] = mapped_column(Text, nullable=False)
    quantity: Mapped[float] = mapped_column(db.Numeric(18, 4), nullable=True)
    price_at_addition: Mapped[float] = mapped_column(db.Numeric(18, 4), nullable=True)
    added_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    watchlist: Mapped[Watchlist] = relationship(back_populates="items")

    __table_args__ = (
        UniqueConstraint("watchlist_id", "symbol", name="uq_watchlist_items_symbol"),
        Index("idx_watchlist_items_watchlist", "watchlist_id"),
    )
