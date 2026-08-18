"""Celery Beat scheduler entry point for backend-scheduler."""

from app import create_app, create_celery_app
from app.extensions import celery as celery_app

flask_app = create_app()
create_celery_app(flask_app)

if __name__ == "__main__":
    celery_app.start(argv=["beat", "--loglevel=info"])
