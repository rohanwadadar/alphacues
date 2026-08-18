from __future__ import annotations

from flask import Flask
from werkzeug.exceptions import HTTPException

from app.shared.exceptions import ApiError, ValidationError
from app.shared.response import json_response


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(ApiError)
    def handle_api_error(error: ApiError):
        return json_response(
            status_code=error.status_code,
            error_code=error.code,
            error_message=error.message,
            error_details=error.details,
        )

    @app.errorhandler(ValidationError)
    def handle_validation_error(error: ValidationError):
        return json_response(
            status_code=error.status_code,
            error_code=error.code,
            error_message=error.message,
            error_details=error.details,
        )

    @app.errorhandler(404)
    def handle_not_found(_error):
        return json_response(
            status_code=404,
            error_code="VALIDATION_ERROR",
            error_message="The requested resource was not found.",
        )

    @app.errorhandler(HTTPException)
    def handle_http_exception(error: HTTPException):
        if error.code == 422:
            return json_response(
                status_code=422,
                error_code="VALIDATION_ERROR",
                error_message=error.description or "Request could not be processed.",
            )
        if error.code and error.code >= 500:
            app.logger.exception("HTTP server error: %s", error)
            return json_response(
                status_code=error.code,
                error_code="SERVICE_UNAVAILABLE",
                error_message=error.description or "Service is unavailable.",
            )
        return json_response(
            status_code=error.code or 400,
            error_code="VALIDATION_ERROR",
            error_message=error.description or "Request could not be processed.",
        )

    @app.errorhandler(Exception)
    def handle_unexpected_error(error: Exception):
        app.logger.exception("Unhandled exception", exc_info=error)
        return json_response(
            status_code=500,
            error_code="SERVICE_UNAVAILABLE",
            error_message="An unexpected error occurred.",
        )
