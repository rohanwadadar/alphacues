"""Stock Universe — local cache of all tradeable symbols from Alpaca.

The ``stock_universe`` table stores every active asset fetched from the
Alpaca ``GET /v2/assets`` endpoint.  Keeping a local copy avoids hitting
an upstream API on every search keystroke.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy import DateTime, Index, Text, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.db import db

logger = logging.getLogger(__name__)


class StockAsset(db.Model):
    """One row per tradeable symbol (e.g. AAPL, TSLA, …)."""

    __tablename__ = "stock_universe"

    symbol: Mapped[str] = mapped_column(Text, primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False, default="")
    exchange: Mapped[str] = mapped_column(Text, nullable=False, default="")
    asset_class: Mapped[str] = mapped_column(Text, nullable=False, default="us_equity")
    tradable: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("idx_stock_universe_name", "name"),
        Index("idx_stock_universe_tradable", "tradable"),
    )

    def to_dict(self) -> dict:
        return {
            "symbol": self.symbol,
            "name": self.name,
            "exchange": self.exchange,
        }
