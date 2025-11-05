.PHONY: poc-up poc-server poc-test

poc-up:
	docker compose -f poc/docker-compose.yml up -d

poc-server:
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	pip install -r poc/requirements.txt && \
	python poc/local_server.py

poc-test:
	python3 poc/test_send_webhook.py
