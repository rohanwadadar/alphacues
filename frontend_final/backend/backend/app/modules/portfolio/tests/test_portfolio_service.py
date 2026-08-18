from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy import func, select

from app.adapters.protocols import SnapshotPayload
from app.modules.portfolio.models import PortfolioEvent, Position
from app.modules.portfolio.service import PortfolioService
from app.shared.db import db
from app.shared.exceptions import ValidationError


@pytest.fixture
def user_id(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "portfolio-service@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("portfolio-service@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "portfolio-service@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    return int(verify.get_json()["data"]["user"]["userId"])


def _record_buy(
    user_id: int,
    *,
    symbol: str = "AAPL",
    price: str = "100.000000",
    volume: int = 10,
    time_stamp: datetime | None = None,
):
    return PortfolioService.record_event(
        user_id,
        symbol=symbol,
        action="BUY",
        price=Decimal(price),
        volume=volume,
        time_stamp=time_stamp or datetime.now(timezone.utc),
    )


def _record_sell(
    user_id: int,
    *,
    symbol: str = "AAPL",
    price: str = "130.000000",
    volume: int = 5,
    time_stamp: datetime | None = None,
):
    return PortfolioService.record_event(
        user_id,
        symbol=symbol,
        action="SELL",
        price=Decimal(price),
        volume=volume,
        time_stamp=time_stamp or datetime.now(timezone.utc),
    )


def _get_position(user_id: int, symbol: str = "AAPL") -> Position:
    position = db.session.scalar(
        select(Position).where(Position.user_id == user_id, Position.symbol == symbol)
    )
    assert position is not None
    return position


def test_buy_increases_position_volume_and_cost_basis(user_id):
    _record_buy(user_id, price="100.000000", volume=10)

    position = _get_position(user_id)
    assert position.volume == 10
    assert position.total_price == Decimal("1000.000000")


def test_sell_decreases_position_using_weighted_avg_cost(user_id):
    _record_buy(user_id, price="100.000000", volume=10)
    _record_buy(user_id, price="120.000000", volume=5)
    _record_sell(user_id, price="130.000000", volume=5)

    position = _get_position(user_id)
    assert position.volume == 10
    assert position.total_price.quantize(Decimal("0.01")) == Decimal("1066.67")


def test_sell_more_than_holdings_raises_validation_error(user_id):
    _record_buy(user_id, price="100.000000", volume=5)

    with pytest.raises(ValidationError, match="Insufficient holdings for SELL"):
        _record_sell(user_id, volume=10)


def test_total_cost_basis_unchanged_by_sale_proceeds(user_id):
    _record_buy(user_id, price="100.000000", volume=10)
    position_before = _get_position(user_id)
    cost_before = position_before.total_price

    _record_sell(user_id, price="200.000000", volume=5)

    position_after = _get_position(user_id)
    expected_cost = cost_before - (cost_before / Decimal(10) * Decimal(5))
    assert position_after.total_price == expected_cost
    assert position_after.total_price == Decimal("500.000000")


@patch("app.modules.portfolio.service._market_service")
def test_unrealized_pl_calculation(mock_market_factory, user_id):
    _record_buy(user_id, price="100.000000", volume=10)

    mock_market = MagicMock()
    mock_market.get_snapshot.return_value = [
        SnapshotPayload(
            symbol="AAPL",
            lastPrice=Decimal("125.000000"),
            changeAmount=Decimal("2.500000"),
            changePercent=Decimal("2.040000"),
            asOf="2026-05-13T14:30:00Z",
        )
    ]
    mock_market_factory.return_value = mock_market

    summary = PortfolioService.get_summary(user_id)

    assert summary["totalValue"] == 1250.0
    assert summary["totalProfit"] == 250.0
    assert summary["dayChange"] == 25.0
    assert summary["availableBalance"] == 0.0


def test_realized_pl_calculation(user_id):
    _record_buy(user_id, price="100.000000", volume=10)
    _record_buy(user_id, price="120.000000", volume=5)
    sell_event = _record_sell(user_id, price="130.000000", volume=5)

    realized = PortfolioService.compute_realized_pl(
        user_id,
        "AAPL",
        up_to_event_id=sell_event.event_id,
    )
    assert realized.quantize(Decimal("0.01")) == Decimal("116.67")

    summary = PortfolioService.get_summary(user_id)
    assert "realized" not in summary


def test_edit_event_recomputes_position_via_replay(user_id):
    buy = _record_buy(user_id, price="100.000000", volume=10)
    _record_sell(user_id, price="130.000000", volume=3)

    PortfolioService.update_event(
        user_id,
        buy.event_id,
        symbol="AAPL",
        action="BUY",
        price=Decimal("110.000000"),
        volume=12,
        time_stamp=buy.time_stamp,
    )

    position = _get_position(user_id)
    assert position.volume == 9
    assert position.total_price.quantize(Decimal("0.01")) == Decimal("990.00")


def test_edit_event_preserves_time_stamp_when_omitted(user_id):
    t1 = datetime(2026, 6, 17, 1, 34, 1, tzinfo=timezone.utc)
    t2 = datetime(2026, 6, 17, 1, 35, 11, tzinfo=timezone.utc)
    t3 = datetime(2026, 6, 17, 1, 35, 37, tzinfo=timezone.utc)

    first_buy = _record_buy(
        user_id, price="100.000000", volume=10, time_stamp=t1
    )
    _record_buy(user_id, price="120.000000", volume=5, time_stamp=t2)
    _record_sell(user_id, price="130.000000", volume=5, time_stamp=t3)

    updated = PortfolioService.update_event(
        user_id,
        first_buy.event_id,
        symbol="AAPL",
        action="BUY",
        price=Decimal("90.000000"),
        volume=10,
    )

    assert updated.time_stamp == t1

    position = _get_position(user_id)
    assert position.volume == 10
    assert position.total_price == Decimal("1000.000000")


def test_delete_event_recomputes_position_via_replay(user_id):
    buy = _record_buy(user_id, price="100.000000", volume=10)
    sell = _record_sell(user_id, price="130.000000", volume=4)

    PortfolioService.delete_event(user_id, sell.event_id)

    position = _get_position(user_id)
    assert position.volume == 10
    assert position.total_price == Decimal("1000.000000")


def test_record_event_rejects_old_explicit_time_stamp(user_id):
    before_count = db.session.scalar(select(func.count()).select_from(PortfolioEvent))

    with pytest.raises(ValidationError, match="Event is outside the editable window"):
        PortfolioService.record_event(
            user_id,
            symbol="AAPL",
            action="BUY",
            price=Decimal("100.000000"),
            volume=1,
            time_stamp=datetime(2000, 1, 1, tzinfo=timezone.utc),
        )

    after_count = db.session.scalar(select(func.count()).select_from(PortfolioEvent))
    assert after_count == before_count


def test_event_outside_settlement_window_rejected(user_id):
    old_time = datetime.now(timezone.utc) - timedelta(hours=25)
    event = PortfolioEvent(
        user_id=user_id,
        symbol="AAPL",
        action="BUY",
        price=Decimal("100.000000"),
        volume=5,
        time_stamp=old_time,
    )
    db.session.add(event)
    db.session.commit()

    with pytest.raises(ValidationError, match="Event is outside the editable window"):
        PortfolioService.update_event(
            user_id,
            event.event_id,
            symbol="AAPL",
            action="BUY",
            price=Decimal("100.000000"),
            volume=5,
            time_stamp=old_time,
        )

    with pytest.raises(ValidationError, match="Event is outside the editable window"):
        PortfolioService.delete_event(user_id, event.event_id)
