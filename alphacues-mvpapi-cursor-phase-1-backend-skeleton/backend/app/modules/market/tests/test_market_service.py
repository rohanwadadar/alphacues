from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

@pytest.fixture
def adapter():
    mock = MagicMock()
    return mock


@pytest.fixture
def cache():
    store: dict[str, str] = {}

    mock = MagicMock()

    def get_json(key: str):
        raw = store.get(key)
        if raw is None:
            return None
        import json

        return json.loads(raw)

    def set_json(key: str, value, *, ttl_seconds: int):
        import json

        store[key] = json.dumps(value)
        mock.last_ttl = ttl_seconds
        mock.last_key = key
        return True

    mock.get_json.side_effect = get_json
    mock.set_json.side_effect = set_json
    mock.acquire_lock.return_value = True
    mock.release_lock.return_value = True
    mock._store = store
    return mock


@pytest.fixture
def service(adapter, cache, app):
    with app.app_context():
        from app.shared.db import db

        yield MarketService(adapter, cache, db.session)


def test_quote_cache_hit(service, adapter, cache):
    service.get_quote("AAPL")
    service.get_quote("AAPL")
    adapter.get_quote.assert_called_once_with("AAPL")


def test_quote_cache_miss(service, adapter, cache):
    service.get_quote("AAPL")
    adapter.get_quote.assert_called_once_with("AAPL")
    assert cache.set_json.called
    assert cache.last_ttl <= 5


@patch("app.modules.market.service.StockTick.upsert_bars")
def test_bars_upserted_to_stock_tick(mock_upsert, service, adapter, cache):
    service.get_bars("AAPL", "1day", "1M")
    adapter.get_bars.assert_called_once_with("AAPL", "1day", "1M")
    mock_upsert.assert_called_once()
    bars_payload = mock_upsert.call_args[0][1]
    assert isinstance(bars_payload, BarsPayload)
    assert bars_payload.bars[0].timeStamp == "2026-05-13T14:30:00Z"


def test_bars_short_timeframe_short_ttl(service, adapter, cache):
    service.get_bars("AAPL", "5min", "1D")
    assert cache.last_ttl <= 60


def test_bars_long_timeframe_longer_ttl(service, adapter, cache):
    service.get_bars("AAPL", "1day", "1M")
    assert cache.last_ttl >= 300


def test_fundamentals_long_ttl(service, adapter, cache):
    service.get_fundamentals("AAPL")
    assert cache.last_ttl >= 21600


def test_snapshot_batches_uncached(service, adapter, cache):
    cache._store["market:snapshot:AAPL"] = (
        '{"symbol":"AAPL","lastPrice":"188.900000","changeAmount":"1.240000",'
        '"changePercent":"0.661200","asOf":"2026-05-13T14:30:01Z"}'
    )
    service.get_snapshot(["AAPL", "MSFT"])
    adapter.get_snapshot.assert_called_once_with(["MSFT"])
