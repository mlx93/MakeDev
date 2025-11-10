.PHONY: help dev seed deploy destroy

# Default target
.DEFAULT_GOAL := help

# ────────────────────────────────────────────────────────────────────────────────
# Help
# ────────────────────────────────────────────────────────────────────────────────
help: ## Show available commands
	@echo "Zero-to-Running Developer Environment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  1. cp config.yaml.example config.yaml"
	@echo "  2. Edit config.yaml with your project details"
	@echo "  3. make dev"

# ────────────────────────────────────────────────────────────────────────────────
# Local Development
# ────────────────────────────────────────────────────────────────────────────────
dev: ## Start local development environment (Docker Compose)
	@echo "🚀 Starting local development environment..."
	@# TODO: Implement by C&C Part 1 agent
	@# - Check prerequisites (Docker, Node.js)
	@# - Read config.yaml
	@# - Clone/detect repository
	@# - If git_repo empty, run scaffold-project.sh
	@# - Build Docker images
	@# - docker-compose up
	@# - Wait for health checks
	@# - Run migrations automatically
	@# - Display URLs (http://localhost:3000, http://localhost:8080)

# ────────────────────────────────────────────────────────────────────────────────
# Data Seeding
# ────────────────────────────────────────────────────────────────────────────────
seed: ## Generate fake data from Prisma schema
	@echo "🌱 Generating seed data..."
	@# TODO: Implement by A&D agent
	@# - Read config.yaml (seed.users, seed.tasks_per_user)
	@# - Parse Prisma schema from services.database.schema_path
	@# - Run seed-database.ts
	@# - Display summary (users created, tasks created)

# ────────────────────────────────────────────────────────────────────────────────
# GKE Deployment
# ────────────────────────────────────────────────────────────────────────────────
deploy: ## Deploy to Google Kubernetes Engine
	@echo "☁️  Deploying to GKE..."
	@# TODO: Implement by C&C Part 2 agent
	@# - Check prerequisites (gcloud, kubectl, terraform)
	@# - Read config.yaml (gke.project_id, gke.region, gke.cluster_name)
	@# - Check for existing cluster, reuse if found
	@# - If not exists, terraform apply (provision cluster)
	@# - Build production images
	@# - Push images to Artifact Registry
	@# - Convert .env.production (or .env) to K8s secrets
	@# - kubectl apply -f k8s/
	@# - Wait for pods ready
	@# - Get LoadBalancer IP
	@# - Display URL and cost estimate

# ────────────────────────────────────────────────────────────────────────────────
# Cleanup
# ────────────────────────────────────────────────────────────────────────────────
destroy: ## Teardown all resources (local + GKE)
	@echo "🧹 Tearing down environment..."
	@# TODO: Implement by C&C Part 2 agent
	@# - Prompt for confirmation
	@# - docker-compose down -v (local)
	@# - kubectl delete -f k8s/ (GKE resources)
	@# - Optionally: terraform destroy (cluster)
	@# - Display cost savings message

