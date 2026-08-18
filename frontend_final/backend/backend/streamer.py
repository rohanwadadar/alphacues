from __future__ import annotations

import json
import logging
import signal
import sys
import time
from decimal import Decimal

from app import create_app
from app.adapters.market_data import _backoff_sleep
from app.extensions import db
from app.modules.market.service import MarketService
from app.shared.cache import CacheService, get_redis
from app.shared.logging import configure_logging

logger = logging.getLogger(__name__)
_shutdown = False


def _handle_shutdown(signum, _frame) -> None:
    global _shutdown
    logger.info("Received signal %s; shutting down streamer", signum)
    _shutdown = True


def _should_stop() -> bool:
    return _shutdown


def _quote_to_dict(quote) -> dict[str, object]:
    return {
        "symbol": quote.symbol,
        "lastPrice": float(quote.lastPrice),
        "changeAmount": float(quote.changeAmount),
        "changePercent": float(quote.changePercent),
        "asOf": quote.asOf,
    }


def _enrich_quote(quote, reference_closes: dict[str, float], market_service: MarketService):
    symbol = quote.symbol
    if symbol not in reference_closes:
        try:
            snapshot = market_service.get_quote(symbol)
            reference_closes[symbol] = float(snapshot.lastPrice) - float(
                snapshot.changeAmount
            )
        except Exception:
            reference_closes[symbol] = float(quote.lastPrice)

    prev_close = reference_closes[symbol]
    last_price = float(quote.lastPrice)
    change_amount = last_price - prev_close
    change_percent = (change_amount / prev_close * 100) if prev_close else 0.0

    from app.adapters.protocols import QuotePayload

    return QuotePayload(
        symbol=symbol,
        lastPrice=Decimal(str(last_price)),
        changeAmount=Decimal(str(change_amount)),
        changePercent=Decimal(str(change_percent)),
        asOf=quote.asOf,
    )


def _publish_tick(
    quote,
    *,
    market_service: MarketService,
    reference_closes: dict[str, float],
) -> None:
    enriched = _enrich_quote(quote, reference_closes, market_service)
    payload = _quote_to_dict(enriched)
    channel = f"quotes:{enriched.symbol}"
    get_redis().publish(channel, json.dumps(payload))
    logger.debug("Published quote tick channel=%s payload=%s", channel, payload)
    market_service.upsert_tick(enriched)
    db.session.commit()


def main() -> int:
    app = create_app()
    configure_logging(app)
    signal.signal(signal.SIGINT, _handle_shutdown)
    signal.signal(signal.SIGTERM, _handle_shutdown)

    with app.app_context():
        adapter = app.extensions["market_data_adapter"]
        stream_url = app.config["ALPACA_STREAM_URL"]
        mock_mode = app.config["MOCK_EXTERNAL_SERVICES"]
        logger.info(
            "Starting backend-streamer (mock=%s, stream_url=%s)",
            mock_mode,
            stream_url,
        )

        market_service = MarketService(
            adapter=adapter,
            cache=CacheService(),
            db_session=db.session,
        )
        reference_closes: dict[str, float] = {}
        attempt = 0

        while not _shutdown:
            try:
                adapter.stream_quotes(
                    stream_url=stream_url,
                    on_quote=lambda quote: _publish_tick(
                        quote,
                        market_service=market_service,
                        reference_closes=reference_closes,
                    ),
                    should_stop=_should_stop,
                )
                attempt = 0
            except Exception as exc:
                if _shutdown:
                    break
                logger.warning(
                    "Alpaca quote stream error: %s; reconnecting", exc, exc_info=True
                )
                _backoff_sleep(attempt)
                attempt = min(attempt + 1, 8)

    logger.info("backend-streamer stopped")
    return 0


if __name__ == "__main__":
    sys.exit(main())
