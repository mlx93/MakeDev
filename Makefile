.PHONY: help config dev seed deploy
# destroy  # DISABLED - Currently disabled for safety

# Default target
.DEFAULT_GOAL := help

# ────────────────────────────────────────────────────────────────────────────────
# Help
# ────────────────────────────────────────────────────────────────────────────────
help: ## Show available commands
	@echo "Zero-to-Running Developer Environment"
	@echo ""
	@echo "Usage: make [target] [SUBDIR=name]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  Option 1 - New project with interactive setup:"
	@echo "    make config SUBDIR=my-app    # Generate config.yaml"
	@echo "    make dev SUBDIR=my-app       # Start development"
	@echo ""
	@echo "  Option 2 - Auto-setup (config during deploy):"
	@echo "    make deploy SUBDIR=my-app    # Will prompt for config if missing"
	@echo ""
	@echo "  Option 3 - Manual config:"
	@echo "    1. cp config.yaml.example config.yaml"
	@echo "    2. Edit config.yaml with your project details"
	@echo "    3. make dev"

# ────────────────────────────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────────────────────────────
config: ## Generate config.yaml interactively
	@if [ -n "$(SUBDIR)" ]; then \
		cd "$(SUBDIR)" && bash ../scripts/setup-config.sh; \
	else \
		bash scripts/setup-config.sh; \
	fi

# ────────────────────────────────────────────────────────────────────────────────
# Local Development
# ────────────────────────────────────────────────────────────────────────────────
dev: ## Start local development environment (Docker Compose)
	@if [ -n "$(SUBDIR)" ]; then \
		bash scripts/dev-subdir.sh "$(SUBDIR)"; \
	else \
		bash scripts/setup-local.sh; \
	fi

# ────────────────────────────────────────────────────────────────────────────────
# Data Seeding
# ────────────────────────────────────────────────────────────────────────────────
seed: ## Generate fake data from Prisma schema
	@echo "🌱 Generating seed data..."
	@if [ -n "$(SUBDIR)" ]; then \
		cd "$(SUBDIR)" && \
		if [ ! -f "config.yaml" ]; then \
			echo "❌ Error: config.yaml not found in $(SUBDIR)"; \
			exit 1; \
		fi && \
		if [ ! -d "backend" ]; then \
			echo "❌ Error: backend directory not found in $(SUBDIR)"; \
			exit 1; \
		fi && \
		if [ ! -f "backend/prisma/schema.prisma" ]; then \
			echo "❌ Error: Prisma schema not found at backend/prisma/schema.prisma"; \
			exit 1; \
		fi && \
		cd backend && \
		if [ ! -d "node_modules" ]; then \
			echo "⚠️  Backend dependencies not found, installing..." && \
			npm install; \
		fi && \
		if [ ! -d "node_modules/@prisma/client" ]; then \
			echo "⚠️  Prisma client not found, generating..." && \
			npx prisma generate; \
		fi && \
		cd .. && \
		export DATABASE_URL="$${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/appdb}" && \
		export NODE_PATH="$$(pwd)/backend/node_modules:$$NODE_PATH" && \
		npx tsx ../scripts/seed-database.ts "$(PWD)/$(SUBDIR)"; \
	else \
		if [ ! -f "config.yaml" ]; then \
			echo "❌ Error: config.yaml not found. Please create it from config.yaml.example"; \
			exit 1; \
		fi && \
		if [ ! -d "backend" ]; then \
			echo "❌ Error: backend directory not found"; \
			exit 1; \
		fi && \
		if [ ! -f "backend/prisma/schema.prisma" ]; then \
			echo "❌ Error: Prisma schema not found at backend/prisma/schema.prisma"; \
			exit 1; \
		fi && \
		cd backend && \
		if [ ! -d "node_modules" ]; then \
			echo "⚠️  Backend dependencies not found, installing..." && \
			npm install; \
		fi && \
		if [ ! -d "node_modules/@prisma/client" ]; then \
			echo "⚠️  Prisma client not found, generating..." && \
			npx prisma generate; \
		fi && \
		cd .. && \
		export DATABASE_URL="$${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/appdb}" && \
		export NODE_PATH="$$(pwd)/backend/node_modules:$$NODE_PATH" && \
		npx tsx scripts/seed-database.ts "$(PWD)"; \
	fi

# ────────────────────────────────────────────────────────────────────────────────
# GKE Deployment
# ────────────────────────────────────────────────────────────────────────────────
deploy: ## Deploy to Google Kubernetes Engine
	@if [ -n "$(SUBDIR)" ]; then \
		cd "$(SUBDIR)" && \
		bash ../scripts/deploy-gke.sh; \
	else \
		bash scripts/deploy-gke.sh; \
	fi

# ────────────────────────────────────────────────────────────────────────────────
# Cleanup
# ────────────────────────────────────────────────────────────────────────────────
# DISABLED: make destroy - Currently disabled for safety (namespace mismatch bug, cluster sharing risks)
# destroy: ## Teardown all resources (local + GKE)
# 	@if [ -n "$(SUBDIR)" ]; then \
# 		cd "$(SUBDIR)" && \
# 		if [ ! -f "config.yaml" ]; then \
# 			echo "❌ Error: config.yaml not found in $(SUBDIR)"; \
# 			exit 1; \
# 		fi && \
# 		bash ../scripts/cleanup.sh; \
# 	else \
# 		if [ ! -f "config.yaml" ]; then \
# 			echo "❌ Error: config.yaml not found. Please create it from config.yaml.example"; \
# 			exit 1; \
# 		fi && \
# 		bash scripts/cleanup.sh; \
# 	fi

