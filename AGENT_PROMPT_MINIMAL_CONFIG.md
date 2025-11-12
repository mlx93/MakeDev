# Agent Prompt: Minimal Config.yaml for make dev, Interactive GCP Prompt for make deploy

## Context

Currently, when running `make dev SUBDIR=hello-world-app`, the `dev-subdir.sh` script creates a full `config.yaml` file by copying `config.yaml.example`, which includes GCP settings with placeholder values like `project_id: "your-gcp-project-id"`. However, `make dev` only actually needs `project.name` and `project.git_repo` from the config file—it doesn't use any GCP settings for local development. This creates an unnecessary configuration burden for users who just want to develop locally, and causes `make deploy` to error if the placeholder GCP project_id hasn't been updated. The ideal workflow should be: `make dev` creates a minimal config.yaml with only what's needed for local development (project name and git_repo), and `make deploy` detects missing GCP settings and prompts the user interactively to enter their GCP project ID at deployment time.

## Required Changes

You need to modify `scripts/dev-subdir.sh` to create a minimal config.yaml file that only includes the `project` section with `name` (derived from SUBDIR) and `git_repo: ""` (for greenfield projects), plus a minimal `services` section with default paths, omitting all GCP/GKE configuration sections entirely. The minimal config.yaml should look like:
```yaml
project:
  name: "hello-world-app"
  git_repo: ""

services:
  frontend:
    path: "./frontend"
  backend:
    path: "./backend"
  database:
    schema_path: "./backend/prisma/schema.prisma"
```

Then, modify `scripts/deploy-gke.sh` to detect when GCP settings are missing or contain placeholder values, and automatically run the interactive `setup-config.sh` script to prompt the user for their GCP project ID, region, and other deployment settings. The detection logic should check if `project_id` is missing, empty, or equals `"your-gcp-project-id"`, and if so, run `setup-config.sh` interactively before proceeding with deployment. Additionally, enhance `setup-config.sh` to provide a better user experience: (1) After prompting for GCP project ID (required), ask the user if they want to use all default settings for the remaining options—if they answer yes, skip all remaining prompts and use defaults, then immediately print a summary table listing all the default settings that were chosen (e.g., "✅ Using default settings: Region: us-central1, Cluster: auto-generated, Machine Type: e2-medium, Nodes: 2, Domain: (none - HTTP mode)"); (2) Make all prompts clearly show the default value in brackets (e.g., "Enter GCP region [us-central1]: "), so users can just press Enter to accept defaults; (3) Ensure the script can read existing `project.name` from config.yaml if it already exists, so it doesn't prompt for project name again. This ensures users only configure GCP settings when they actually need to deploy, provides a quick path for users who want to accept all defaults after entering their project ID, and gives them clear visibility into what settings were applied.

## Implementation Details

In `scripts/dev-subdir.sh`, replace the section that copies `config.yaml.example` to `config.yaml` (around lines 77-86 and 120-136) with code that generates a minimal YAML file containing only `project.name` (set to the SUBDIR value), `project.git_repo: ""`, and minimal `services` section with default paths. In `scripts/deploy-gke.sh`, enhance the existing config.yaml check (around lines 58-72 and 130-134) to also validate that GCP project_id is present and not a placeholder—if it's missing or equals `"your-gcp-project-id"`, run `setup-config.sh` interactively. In `scripts/setup-config.sh`, add the following improvements: (1) Read `project.name` from existing config.yaml if it exists, and only prompt for it if missing; (2) After prompting for GCP project ID (required), add a prompt: "Use all default settings for region, cluster name, machine type, etc.? (Y/n): " - if user answers yes or presses Enter, skip all remaining prompts and use defaults (us-central1, auto-generated cluster name, e2-medium, 2 nodes, empty domain), then immediately print a formatted summary table showing all default settings that were applied (format: "✅ Using default settings:" followed by a clear list like "  Region: us-central1", "  Cluster Name: <project_name>-cluster (auto-generated)", "  Machine Type: e2-medium", "  Node Count: 2", "  Domain: (none - HTTP mode)"); (3) Update all prompts to show defaults in brackets format like "Enter GCP region [us-central1]: " so users can see defaults clearly; (4) Ensure `setup-config.sh` can handle being called from within a subdirectory context (it should work when called from `deploy-gke.sh` which runs in the project subdirectory). Test that `make dev SUBDIR=test-app` creates minimal config.yaml without GCP settings, and that `make deploy SUBDIR=test-app` prompts for GCP project ID interactively with the option to accept all defaults (and shows the default settings summary), then proceeds with deployment successfully. Do not modify any other functionality—only change how config.yaml is created during `make dev`, how GCP settings are validated/prompted during `make deploy`, and improve the UX of `setup-config.sh` to support quick default acceptance with clear visibility into applied settings.

