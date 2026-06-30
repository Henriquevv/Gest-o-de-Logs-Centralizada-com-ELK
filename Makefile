.PHONY: setup up down logs generate verify backup clean

setup:
	./scripts/setup.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=100

generate:
	./scripts/generate_logs.sh

verify:
	./scripts/verify.sh

backup:
	./scripts/backup.sh

clean:
	docker compose down -v
