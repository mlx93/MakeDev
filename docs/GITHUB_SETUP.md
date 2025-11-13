# GitHub Repository Setup

When you scaffold a new project with `make dev`, a **local Git repository** is automatically created. To connect it to GitHub (required for `make deploy`):

## Quick Setup

1. **Create a new repository on GitHub**
   - Go to https://github.com/new
   - Name it (e.g., `my-test-app`)
   - Don't initialize with README, .gitignore, or license (we already have these)

2. **Add the remote and push**
   ```bash
   cd my-test-app  # or your project directory
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git branch -M main
   git push -u origin main
   ```

3. **Update `config.yaml`** (if needed)
   ```yaml
   project:
     git_repo: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   ```

## Important Notes

- The scaffold process only creates a **local** Git repository
- No remote repository is created automatically - you must do this manually
- **Required for `make deploy`**: The deployment process needs a GitHub repository URL

## For `make deploy`

After setting up the GitHub repository and pushing your code, you can run:

```bash
make deploy
```

The `make deploy` command uses the `git_repo` from `config.yaml` to deploy to Google Kubernetes Engine (GKE).

