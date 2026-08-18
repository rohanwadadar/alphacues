from __future__ import annotations

import uuid
from typing import Any

from flask import Response, g, jsonify, request


def get_request_id() -> str:
    request_id = getattr(g, "request_id", None)
    if request_id:
        return request_id
    header_value = request.headers.get("X-Request-Id")
    if header_value:
        return header_value
    return str(uuid.uuid4())


def _envelope_meta(
    request_id: str,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    meta: dict[str, Any] = {
        "requestId": request_id,
        "apiVersion": "1",
    }
    if extra:
        meta.update(extra)
    return meta


class ResponseFactory:
    @classmethod
    def success(
        cls,
        data: Any,
        *,
        status_code: int = 200,
        request_id: str | None = None,
    ) -> tuple[dict[str, Any], int]:
        resolved_request_id = request_id or get_request_id()
        body = {
            "success": True,
            "data": data,
            "error": None,
            "meta": _envelope_meta(resolved_request_id),
        }
        return body, status_code

    @classmethod
    def error(
        cls,
        *,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
        status_code: int = 400,
        request_id: str | None = None,
    ) -> tuple[dict[str, Any], int]:
        resolved_request_id = request_id or get_request_id()
        body = {
            "success": False,
            "data": None,
            "error": {
                "code": code,
                "message": message,
                "details": details or {},
            },
            "meta": _envelope_meta(resolved_request_id),
        }
        return body, status_code


def json_response(
    data: Any = None,
    *,
    status_code: int = 200,
    error_code: str | None = None,
    error_message: str | None = None,
    error_details: dict[str, Any] | None = None,
    request_id: str | None = None,
    meta: dict[str, Any] | None = None,
) -> Response:
    resolved_request_id = request_id or get_request_id()
    if error_code is not None:
        body, status_code = ResponseFactory.error(
            code=error_code,
            message=error_message or error_code,
            details=error_details,
            status_code=status_code,
            request_id=resolved_request_id,
        )
    else:
        body, status_code = ResponseFactory.success(
            data,
            status_code=status_code,
            request_id=resolved_request_id,
        )
    body["meta"] = _envelope_meta(resolved_request_id, meta)
    response = jsonify(body)
    response.status_code = status_code
    response.headers["X-Request-Id"] = resolved_request_id
    return response
