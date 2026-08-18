BACKEND_DIR := backend
VENV_BIN := $(BACKEND_DIR)/.venv/bin
COMPOSE_FILE := docker-compose.yml

export APP_ENV := testing
export FLASK_ENV := testing
export FLASK_APP := wsgi.py
export DATABASE_URL ?= postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues_test
export REDIS_URL ?= redis://localhost:6379/0
export MIGRATION_TEST_DATABASE_URL ?= postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues_migration_test

.PHONY: up lint backend-test ensure-test-db

up:
	docker compose up -d

ensure-test-db:
	@docker compose exec -T postgres psql -U alphacues -d alphacues -tc \
		"SELECT 1 FROM pg_database WHERE datname = 'alphacues_test'" | grep -q 1 || \
		docker compose exec -T postgres psql -U alphacues -d alphacues -c \
		"CREATE DATABASE alphacues_test;"
	@docker compose exec -T postgres psql -U alphacues -d alphacues_test \
		-c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

lint:
	cd $(BACKEND_DIR) && .venv/bin/flake8 app/ tests/
	cd $(BACKEND_DIR) && .venv/bin/black --check app/ tests/
	cd $(BACKEND_DIR) && .venv/bin/isort --check-only app/ tests/

backend-test: up ensure-test-db
	@echo "Waiting for Postgres and Redis..."
	@until docker compose exec -T postgres pg_isready -U alphacues -d alphacues >/dev/null 2>&1; do sleep 1; done
	@until docker compose exec -T redis redis-cli ping | grep -q PONG; do sleep 1; done
	$(VENV_BIN)/pip install -r $(BACKEND_DIR)/requirements.txt -r $(BACKEND_DIR)/requirements-dev.txt
	cd $(BACKEND_DIR) && .venv/bin/flask db upgrade
	cd $(BACKEND_DIR) && .venv/bin/flask db check
	cd $(BACKEND_DIR) && .venv/bin/pytest
