from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.db import db

ALERT_CONDITIONS = ("ABOVE", "BELOW", "PERCENT_CHANGE")

class Alert(db.Model):
    __tablename__ = "alerts"

    alert_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), ForeignKey("users.user_id"), nullable=False
    )
    symbol: Mapped[str] = mapped_column(Text, nullable=False)
    condition: Mapped[str] = mapped_column(Text, nullable=False)
    target: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    triggered: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    cooldown_seconds: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    last_triggered_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "condition IN ('ABOVE','BELOW','PERCENT_CHANGE')",
            name="ck_alerts_condition",
        ),
        Index("idx_alerts_user", "user_id"),
        Index("idx_alerts_active", "is_active"),
        Index("idx_alerts_symbol_active", "symbol", "is_active"),
    )


class AlertTriggerEvent(db.Model):
    __tablename__ = "alert_trigger_events"

    id: Mapped[int] = mapped_column(BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True)
    alert_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), ForeignKey("alerts.alert_id"), nullable=False
    )
    triggered_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    trigger_price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
