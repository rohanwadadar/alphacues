from __future__ import annotations

from flask import Blueprint, jsonify, request

from app.modules.news.service import NewsService
from app.shared.response import ResponseFactory

news_bp = Blueprint("news", __name__)


@news_bp.route("", methods=["GET"])
def list_news():
    symbol = request.args.get("symbol")
    limit = request.args.get("limit", default=15, type=int)
    articles = NewsService.get_market_news(symbol=symbol, limit=limit)
    return ResponseFactory.success(data=articles)


@news_bp.route("/<news_id>", methods=["GET"])
def get_news_detail(news_id: str):
    article = NewsService.get_article_by_id(news_id)
    if not article:
        return ResponseFactory.error(code="NOT_FOUND", message="Article not found", status_code=404)
    return ResponseFactory.success(data=article)
