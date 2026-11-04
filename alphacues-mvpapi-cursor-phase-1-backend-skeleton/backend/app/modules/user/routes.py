from __future__ import annotations

from flask import Blueprint, g, request
from flask_cors import CORS
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
CORS(auth_bp)

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
    from flask import current_app
    limit_str = f"{current_app.config.get('RATE_LIMIT_AUTH_PER_MINUTE', 30)} per minute" if current_app else "30 per minute"
    return limiter.limit(
        limit_str,
        key_func=auth_ip_key,
        on_breach=on_rate_limit_breach,
    )


def _refresh_rate_limit():
    return limiter.limit(
        "60 per minute",
        key_func=auth_ip_key,
        on_breach=on_rate_limit_breach,
    )


@auth_bp.route("/check-email", methods=["POST", "OPTIONS"])
@_auth_rate_limit()
def check_email():
    if request.method == "OPTIONS":
        return json_response({})
    data = _load_json(send_otp_schema)
    email = normalize_email(data["email"])
    result = _auth_service().check_email(email)
    return json_response(result)


@auth_bp.route("/register-send-otp", methods=["POST", "OPTIONS"])
@_auth_rate_limit()
def register_send_otp():
    if request.method == "OPTIONS":
        return json_response({})
    data = _load_json(send_otp_schema)
    email = normalize_email(data["email"])
    bind_rate_limit_email(email)
    result = _auth_service().send_otp(email, allow_new_user=True)
    return json_response(result, status_code=201)


@auth_bp.route("/send-otp", methods=["POST", "OPTIONS"])
@_auth_rate_limit()
def send_otp():
    if request.method == "OPTIONS":
        return json_response({})
    data = _load_json(send_otp_schema)
    email = normalize_email(data["email"])
    bind_rate_limit_email(email)
    # Existing login flow: only for already-registered users
    result = _auth_service().send_otp(email, allow_new_user=False)
    return json_response(result, status_code=201)


@auth_bp.route("/verify-otp", methods=["POST", "OPTIONS"])
@_auth_rate_limit()
def verify_otp():
    if request.method == "OPTIONS":
        return json_response({})
    data = _load_json(verify_otp_schema)
    email = normalize_email(data["email"])
    bind_rate_limit_email(email)
    result = _auth_service().verify_otp(
        email=email,
        challenge_id=data["otpChallengeId"],
        otp_code=data["otpCode"],
    )
    return json_response(result)


@auth_bp.route("/refresh", methods=["POST", "OPTIONS"])
@_refresh_rate_limit()
def refresh_tokens():
    if request.method == "OPTIONS":
        return json_response({})
    data = _load_json(refresh_schema)
    result = _auth_service().refresh_tokens(data["refreshToken"])
    return json_response(result)


@auth_bp.route("/logout", methods=["POST", "OPTIONS"])
@_auth_rate_limit()
def logout():
    if request.method == "OPTIONS":
        return json_response({})
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


@auth_bp.route("/verify", methods=["GET", "OPTIONS"])
def verify_token():
    if request.method == "OPTIONS":
        return json_response({})
    token = extract_bearer_token()
    result = _auth_service().verify_access(token)
    return json_response(result)


@auth_bp.route("/me", methods=["GET", "PUT", "OPTIONS"])
@auth_bp.route("/profile", methods=["GET", "PUT", "OPTIONS"])
@require_auth
def get_me():
    if request.method == "OPTIONS":
        return json_response({})
    user_id = int(g.user_id)
    if request.method == "PUT":
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
        result = _auth_service().update_profile(
            user_id,
            **data,
        )
        return json_response(result)

    result = _auth_service().get_profile(user_id)
    return json_response(result)
