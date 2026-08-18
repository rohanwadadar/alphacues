from flask import Blueprint, jsonify, request, g
from marshmallow import Schema, fields, validate, ValidationError

from app.shared.auth import require_auth
from app.modules.notifications.service import DevicePushTokenService
from app.shared.response import json_response

devices_bp = Blueprint("devices", __name__)


def _get_user_id() -> int:
    return int(g.user_id)


class RegisterDeviceSchema(Schema):
    fcmToken = fields.String(required=True)
    platform = fields.String(required=True, validate=validate.OneOf(["ios", "android"]))
    appVersion = fields.String(required=False, allow_none=True)
    deviceId = fields.String(required=True)


class DevicePreferencesSchema(Schema):
    is_active = fields.Boolean(required=True)


@devices_bp.route("/register", methods=["POST"])
@require_auth
def register_device():
    try:
        data = RegisterDeviceSchema().load(request.json)
    except ValidationError as err:
        from werkzeug.exceptions import UnprocessableEntity
        raise UnprocessableEntity(description=err.messages)

    user_id = _get_user_id()
    token = DevicePushTokenService.register_token(
        user_id=user_id,
        device_id=data["deviceId"],
        fcm_token=data["fcmToken"],
        platform=data["platform"],
        app_version=data.get("appVersion")
    )
    
    return json_response({
        "deviceId": token.device_id,
        "isActive": token.is_active
    })


@devices_bp.route("/<device_id>", methods=["DELETE"])
@require_auth
def unregister_device(device_id: str):
    user_id = _get_user_id()
    DevicePushTokenService.unregister_token(user_id=user_id, device_id=device_id)
    return "", 204


@devices_bp.route("/<device_id>/preferences", methods=["PUT"])
@require_auth
def update_preferences(device_id: str):
    try:
        data = DevicePreferencesSchema().load(request.json)
    except ValidationError as err:
        from werkzeug.exceptions import UnprocessableEntity
        raise UnprocessableEntity(description=err.messages)

    user_id = _get_user_id()
    token = DevicePushTokenService.update_preferences(
        user_id=user_id,
        device_id=device_id,
        is_active=data["is_active"]
    )
    
    return json_response({
        "deviceId": token.device_id,
        "isActive": token.is_active
    })


