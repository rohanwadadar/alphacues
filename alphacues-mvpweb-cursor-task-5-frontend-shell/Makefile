FRONTEND_DIR := frontend

.PHONY: frontend-test lint

frontend-test:
	cd $(FRONTEND_DIR) && flutter test

lint:
	cd $(FRONTEND_DIR) && flutter analyze
	cd $(FRONTEND_DIR) && dart format --set-exit-if-changed .
