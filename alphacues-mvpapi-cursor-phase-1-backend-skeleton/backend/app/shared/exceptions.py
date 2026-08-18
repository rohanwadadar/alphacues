from __future__ import annotations

from typing import Any


class ApiError(Exception):
    status_code = 400
    code = "VALIDATION_ERROR"
    message = "Request could not be processed."
    details: dict[str, Any]

    def __init__(
        self,
        message: str | None = None,
        *,
        details: dict[str, Any] | None = None,
        code: str | None = None,
        status_code: int | None = None,
    ) -> None:
        super().__init__(message or self.message)
        if message is not None:
            self.message = message
        if code is not None:
            self.code = code
        if status_code is not None:
            self.status_code = status_code
        self.details = details or {}


class ValidationError(ApiError):
    status_code = 422
    code = "VALIDATION_ERROR"


class UnauthorizedError(ApiError):
    status_code = 401
    code = "UNAUTHORIZED"


class TokenExpiredError(ApiError):
    status_code = 401
    code = "TOKEN_EXPIRED"


class OtpInvalidError(ApiError):
    status_code = 401
    code = "OTP_INVALID"


class OtpExpiredError(ApiError):
    status_code = 401
    code = "OTP_EXPIRED"


class OtpChallengeNotFoundError(ApiError):
    status_code = 404
    code = "OTP_CHALLENGE_NOT_FOUND"


class OtpLockedError(ApiError):
    status_code = 429
    code = "OTP_LOCKED"


class RateLimitedError(ApiError):
    status_code = 429
    code = "RATE_LIMITED"


class NotFoundError(ApiError):
    status_code = 404
    code = "NOT_FOUND"


class EventNotFoundError(ApiError):
    status_code = 404
    code = "EVENT_NOT_FOUND"
    message = "Portfolio event was not found."


class DuplicateSymbolError(ApiError):
    status_code = 409
    code = "DUPLICATE_SYMBOL"


class FeatureDisabledError(ApiError):
    status_code = 403
    code = "FEATURE_DISABLED"


class UpstreamTimeoutError(ApiError):
    status_code = 504
    code = "UPSTREAM_TIMEOUT"


class ServiceUnavailableError(ApiError):
    status_code = 503
    code = "SERVICE_UNAVAILABLE"
