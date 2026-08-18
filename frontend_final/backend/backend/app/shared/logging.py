from __future__ import annotations

import logging
import sys
import uuid
from typing import TYPE_CHECKING

from flask import Flask, g, request

if TYPE_CHECKING:
    pass


def configure_logging(app: Flask) -> None:
    log_level = getattr(
        logging,
        app.config.get("LOG_LEVEL", "INFO").upper(),
        logging.INFO,
    )

    root_logger = logging.getLogger()
    if not root_logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)s [%(name)s] "
                "requestId=%(requestId)s %(message)s"
            )
        )
        root_logger.addHandler(handler)

    root_logger.setLevel(log_level)
    app.logger.setLevel(log_level)

    old_factory = logging.getLogRecordFactory()

    def record_factory(*args, **kwargs):
        record = old_factory(*args, **kwargs)
        if not hasattr(record, "requestId"):
            record.requestId = "-"
        return record

    logging.setLogRecordFactory(record_factory)


def bind_request_id(request_id: str) -> None:
    old_factory = logging.getLogRecordFactory()

    def record_factory(*args, **kwargs):
        record = old_factory(*args, **kwargs)
        record.requestId = request_id
        return record

    logging.setLogRecordFactory(record_factory)


SLOW_ENDPOINT_THRESHOLD_MS = 200.0

logger = logging.getLogger(__name__)


def register_request_correlation(app: Flask) -> None:
    @app.before_request
    def assign_request_id() -> None:
        import time
        request_id = request.headers.get("X-Request-Id") or str(uuid.uuid4())
        g.request_id = request_id
        g.start_time = time.monotonic()
        bind_request_id(request_id)

    @app.after_request
    def attach_request_id_header(response):
        import time
        request_id = getattr(g, "request_id", None)
        if request_id:
            response.headers["X-Request-Id"] = request_id

        start_time = getattr(g, "start_time", None)
        if start_time is not None:
            duration_ms = (time.monotonic() - start_time) * 1000.0
            g.duration_ms = duration_ms
            threshold = app.config.get("SLOW_ENDPOINT_THRESHOLD_MS", SLOW_ENDPOINT_THRESHOLD_MS)
            if duration_ms >= threshold:
                logger.warning(
                    "SLOW_ENDPOINT method=%s path=%s status=%d duration_ms=%.2fms threshold_ms=%.2fms",
                    request.method,
                    request.path,
                    response.status_code,
                    duration_ms,
                    threshold,
                )
        return response


# Auth Abuse Signal Logging Helpers
auth_logger = logging.getLogger("app.auth.abuse")


def log_otp_request(email_masked: str) -> None:
    auth_logger.info(
        "AUTH_OTP_REQUESTED email_masked=%s remote_addr=%s",
        email_masked,
        request.remote_addr if request else "N/A",
    )


def log_otp_failed(email_masked: str, attempts_left: int) -> None:
    auth_logger.warning(
        "AUTH_OTP_FAILED email_masked=%s attempts_left=%d remote_addr=%s",
        email_masked,
        attempts_left,
        request.remote_addr if request else "N/A",
    )


def log_otp_lockout(email_masked: str, lock_duration_minutes: int = 15) -> None:
    auth_logger.error(
        "AUTH_OTP_LOCKED_OUT email_masked=%s lock_duration_mins=%d remote_addr=%s",
        email_masked,
        lock_duration_minutes,
        request.remote_addr if request else "N/A",
    )


def log_rate_limit_exceeded(endpoint: str) -> None:
    auth_logger.warning(
        "RATE_LIMITED endpoint=%s remote_addr=%s status_code=429",
        endpoint,
        request.remote_addr if request else "N/A",
    )


def log_token_refresh_failed(reason: str) -> None:
    auth_logger.warning(
        "AUTH_REFRESH_FAILED reason=%s remote_addr=%s",
        reason,
        request.remote_addr if request else "N/A",
    )


