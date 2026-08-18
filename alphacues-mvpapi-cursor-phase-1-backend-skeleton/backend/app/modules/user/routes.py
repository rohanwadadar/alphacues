from __future__ import annotations

from flask import Blueprint, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.user.schemas import (
    LogoutSchema,
    RefreshTokenSchema,
    SendOtpSchema,
    UpdateProfileSchema,
    VerifyOtpSchema,
)
from app.modules.user.service import AuthService, normalize_email
from app.shared.auth import extract_bearer_token, require_auth
from app.shared.exceptions import ValidationError
from app.shared.limiter import (
    auth_ip_key,
    bind_rate_limit_email,
    limiter,
    on_rate_limit_breach,
)
from app.shared.response import json_response

auth_bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")

send_otp_schema = SendOtpSchema()
verify_otp_schema = VerifyOtpSchema()
refresh_schema = RefreshTokenSchema()
logout_schema = LogoutSchema()
update_profile_schema = UpdateProfileSchema()


def _auth_service() -> AuthService:
    return AuthService()


def _load_json(schema):
    payload = request.get_json(silent=True)
    if payload is None:
        raise ValidationError(
            message="Request body must be valid JSON.",
            details={"field": "body"},
        )
    try:
        return schema.load(payload)
    except MarshmallowValidationError as exc:
        raise ValidationError(
            message="Request validation failed.",
            details=exc.normalized_messages(),
        ) from exc


def _auth_rate_limit():
    return limiter.limit(
        "5 per minute",
        key_func=auth_ip_key,
        on_breach=on_rate_limit_breach,
    )


@auth_bp.post("/send-otp")
@_auth_rate_limit()
def send_otp():
    data = _load_json(send_otp_schema)
    email = normalize_email(data["email"])
    bind_rate_limit_email(email)
    result = _auth_service().send_otp(email)
    return json_response(result, status_code=201)


@auth_bp.post("/verify-otp")
@_auth_rate_limit()
def verify_otp():
    data = _load_json(verify_otp_schema)
    email = normalize_email(data["email"])
    bind_rate_limit_email(email)
    result = _auth_service().verify_otp(
        email=email,
        challenge_id=data["otpChallengeId"],
        otp_code=data["otpCode"],
    )
    return json_response(result)


@auth_bp.post("/refresh")
@_auth_rate_limit()
def refresh_tokens():
    data = _load_json(refresh_schema)
    result = _auth_service().refresh_tokens(data["refreshToken"])
    return json_response(result)


@auth_bp.post("/logout")
@_auth_rate_limit()
def logout():
    refresh_token = None
    access_token = None
    payload = request.get_json(silent=True) or {}
    if payload:
        try:
            parsed = logout_schema.load(payload)
            refresh_token = parsed.get("refreshToken")
        except MarshmallowValidationError as exc:
            raise ValidationError(
                message="Request validation failed.",
                details=exc.normalized_messages(),
            ) from exc
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        access_token = auth_header.removeprefix("Bearer ").strip() or None
    result = _auth_service().logout(
        refresh_token=refresh_token,
        access_token=access_token,
    )
    return json_response(result)


@auth_bp.get("/verify")
def verify_token():
    token = extract_bearer_token()
    result = _auth_service().verify_access(token)
    return json_response(result)


@auth_bp.get("/me")
@require_auth
def get_me():
    user_id = int(g.user_id)
    result = _auth_service().get_profile(user_id)
    return json_response(result)


@auth_bp.put("/me")
@require_auth
def update_me():
    payload = request.get_json(silent=True)
    if payload is None:
        raise ValidationError(
            message="Request body must be valid JSON.",
            details={"field": "body"},
        )
    try:
        data = update_profile_schema.load(payload, partial=True)
    except MarshmallowValidationError as exc:
        raise ValidationError(
            message="Request validation failed.",
            details=exc.normalized_messages(),
        ) from exc
    fields_set = set(payload.keys())
    user_id = int(g.user_id)
    result = _auth_service().update_profile(
        user_id,
        name=data.get("name"),
        avatar_url=data.get("avatarUrl"),
        fields_set=fields_set,
    )
    return json_response(result)
