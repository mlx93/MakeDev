# Zero-to-Running Developer Environment
## Developer Setup Instructions (For Building the Tool)

**Version:** 3.0  
**Last Updated:** November 11, 2025  
**Target Platform:** macOS only  
**Audience:** Tool developers (not end users)

---

## Quick Install

**One-line install commands:**

```bash
# Install all prerequisites
brew install --cask docker google-cloud-sdk && \
brew install node@20 kubectl && \
brew tap hashicorp/tap && \
brew install hashicorp/tap/terraform && \
brew link node@20
```

**GCP Setup:**
```bash
gcloud init && \
gcloud auth login && \
gcloud auth application-default login && \
gcloud services enable container.googleapis.com compute.googleapis.com artifactregistry.googleapis.com
```

---

## Quick Verification

```bash
docker --version && \
node --version && \
gcloud --version && \
kubectl version --client && \
terraform --version && \
echo "✅ All tools installed!"
```

---

## Development Workflow

1. **Clone repository:**
   ```bash
   git clone https://github.com/wander/zero-to-running-dev-env.git
   cd zero-to-running-dev-env
   ```

2. **Test locally:**
   ```bash
   make dev SUBDIR=test-app
   ```

3. **Test deployment:**
   ```bash
   make deploy SUBDIR=test-app  # Requires GCP project configured
   ```

---

## System Requirements

- **macOS**: 12 (Monterey) or later
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB free space

---

**Note:** End users should see `README.md` instead. This document is for tool developers only.
