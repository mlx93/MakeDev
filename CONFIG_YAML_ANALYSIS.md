# Config.yaml Analysis: Minimal Config Impact Assessment

## Summary of Findings

### 1. Git Repo Handling During `make deploy`

**Answer: YES, `make deploy` will automatically create a GitHub repo if `git_repo` is empty.**

- `setup-github.sh` (called by `deploy-gke.sh`) **does NOT** check if `git_repo` is empty to decide whether to create a repo
- Instead, it checks if a GitHub repo with name `$PROJECT_NAME` already exists
- If repo doesn't exist, it automatically creates a **new private repository** using `gh repo create "$PROJECT_NAME"`
- After creation, it updates `config.yaml` with the new repo URL
- **So `git_repo: ""` is fine** - the script will create the repo automatically during deployment

### 2. What Settings Will Users Be Prompted For During `make deploy`?

If `setup-config.sh` runs interactively (when GCP settings are missing), users will be prompted for:

**Required (no defaults):**
- **GCP Project ID** (required, cannot be empty)

**Optional (has defaults, but user can override):**
- **GitHub Repo Name** (defaults to project name)
- **GCP Region** (defaults to `us-central1`)
- **Cluster Name** (defaults to `$project_name-cluster`)
- **Machine Type** (defaults to `e2-medium`)
- **Node Count** (defaults to `2`)
- **Domain Name** (optional, empty = HTTP mode)

**Note:** `deploy-gke.sh` has defaults for all GCP settings except `project_id`, so if `setup-config.sh` doesn't run, the script will use defaults. However, `project_id` is required and will cause an error if missing or placeholder.

### 3. Will Minimal Config.yaml Break `make dev`?

**Answer: NO, minimal config.yaml should NOT cause issues for `make dev`.**

**What `make dev` actually reads from config.yaml:**
- `project.name` (required, but has default: "my-app")
- `project.git_repo` (can be empty, used to determine scaffold vs clone)
- `services.frontend.path` (has default: "./frontend")
- `services.backend.path` (has default: "./backend")
- `services.database.schema_path` (has default: "./backend/prisma/schema.prisma")

**What `make dev` does NOT read:**
- Any `gke.*` settings (GCP configuration)
- `seed.*` settings (only used by `make seed`)

**Scripts that read config.yaml during `make dev`:**
1. `setup-local.sh` - Only reads `project.name` and `project.git_repo`
2. `scaffold-project.sh` - Only reads `project.name` and service paths (all have defaults)

**Conclusion:** A minimal config.yaml with only:
```yaml
project:
  name: "hello-world-app"
  git_repo: ""
```

Should work perfectly fine for `make dev`. The GCP settings are only needed for `make deploy`.

### 4. Potential Edge Cases to Consider

1. **If user manually edits config.yaml** between `make dev` and `make deploy`:
   - If they add GCP settings incorrectly, `deploy-gke.sh` will error
   - If they leave GCP settings out, `setup-config.sh` will run interactively
   - This is fine - the interactive prompt will fix it

2. **If `setup-config.sh` is called from subdirectory context**:
   - Currently `setup-config.sh` uses `$(pwd)` for `PROJECT_ROOT`
   - When called from `deploy-gke.sh` (which runs in project subdirectory), this should work correctly
   - But should verify that `setup-config.sh` can handle being called from a subdirectory

3. **Service paths in minimal config**:
   - If we omit `services:` section entirely, scripts use defaults
   - This should be fine, but we could include minimal `services:` section for clarity
   - Recommendation: Include minimal `services:` section with just paths (no ports needed, they're fixed)

### 5. Recommended Minimal Config.yaml Structure

For `make dev`, create:
```yaml
project:
  name: "hello-world-app"  # or SUBDIR name
  git_repo: ""

services:
  frontend:
    path: "./frontend"
  backend:
    path: "./backend"
  database:
    schema_path: "./backend/prisma/schema.prisma"
```

This includes everything `make dev` needs, nothing it doesn't, and `make deploy` will prompt for GCP settings interactively.

