"""Quote-subscription stress test (many symbols / concurrent updates against socket fan-out)."""
import json
from datetime import datetime, timezone
from app.shared.websocket import _handle_quote_message, flush_quote_batch, quote_batcher

def test_quote_fanout_microbatching(app):
    """Stress tests quote batching/fanout under high tick rates."""
    now_iso = datetime.now(timezone.utc).isoformat()

    symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX", "AMD", "INTC"]
    
    with app.app_context():
        # Buffer multiple ticks across symbols
        for symbol in symbols:
            for tick in range(5):
                payload = json.dumps({
                    "symbol": symbol,
                    "lastPrice": 150.0 + tick,
                    "changeAmount": 1.5,
                    "changePercent": 1.0,
                    "asOf": now_iso,
                })
                _handle_quote_message(app, f"quotes:{symbol}", payload, batch=True)

        # Flush coalesced batch
        flushed_count = flush_quote_batch()

        # Coalesced count should equal unique symbols (10) rather than total ticks (50)
        assert flushed_count == len(symbols)
