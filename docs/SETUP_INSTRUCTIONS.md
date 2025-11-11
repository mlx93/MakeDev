# Zero-to-Running Developer Environment
## Developer Setup Instructions (For Building the Tool)

**Version:** 2.0  
**Last Updated:** November 10, 2025  
**Target Platform:** macOS only  
**Estimated Setup Time:** 30-45 minutes (one-time)

---

## ⚠️ When Do You Need This?

**You need these tools to TEST what the agents build, not to spawn agents.**

- **Before spawning agents**: ❌ Not needed - agents generate code, don't run it
- **After agents build code**: ✅ Needed - to test `make dev`, `make deploy`, etc.
- **To verify the tool works**: ✅ Needed - run the tool locally and on GKE

**TL;DR**: Set up your machine AFTER agents generate code, or when you're ready to test.

---

## Quick Summary

Install these tools on your Mac to build and test the Zero-to-Running tool:

1. **Docker Desktop** - Container runtime
2. **Node.js 20 LTS** - Runtime for scripts
3. **Google Cloud SDK** - GCP CLI tools
4. **kubectl** - Kubernetes CLI
5. **Terraform** - Infrastructure provisioning

Then authenticate with GCP and you're ready to build!

---

## 1. Install Required Tools

### Docker Desktop
```bash
brew install --cask docker
```
- Open Docker Desktop from Applications
- Wait for "Docker Desktop is running" in menu bar
- Verify: `docker --version` (should show 24.0.0+)

### Node.js 20 LTS
```bash
brew install node@20
brew link node@20
```
- Verify: `node --version` (should show v20.x.x)

### Google Cloud SDK
```bash
brew install --cask google-cloud-sdk
```
- Initialize: `gcloud init`
- Login: `gcloud auth login`
- Set application default: `gcloud auth application-default login`
- Verify: `gcloud --version`

### kubectl
```bash
brew install kubectl
```
- Or via gcloud: `gcloud components install kubectl`
- Verify: `kubectl version --client`

### Terraform
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```
- Verify: `terraform --version` (should show 1.6.0+)

---

## 2. GCP Setup

### Prerequisites
- GCP project already exists (you'll provide project ID in config.yaml)
- Billing enabled on project

### One-Time Setup
```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com

# Set default region
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

### Verify Authentication
```bash
gcloud auth list  # Should show your account
gcloud auth application-default print-access-token  # Should print token
```

---

## 3. Verify Installation

Run this quick check:
```bash
docker --version && \
node --version && \
gcloud --version && \
kubectl version --client && \
terraform --version && \
echo "✅ All tools installed!"
```

---

## 4. Clone & Configure Tool

```bash
# Clone the tool repository
cd ~/workspace
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env

# Create config.yaml
cp config.yaml.example config.yaml
nano config.yaml  # Edit with your GCP project ID
```

**Minimal config.yaml:**
```yaml
project:
  name: my-test-app

gke:
  project_id: "your-gcp-project-id"  # Your actual project ID
  region: us-central1
```

---

## 5. Test Installation

```bash
# Test Docker
docker run hello-world

# Test GCP access
gcloud projects list

# Test Terraform
terraform version
```

---

## Troubleshooting

**Docker not running:**
- Open Docker Desktop app, wait for "running" status

**Port conflicts:**
- Change ports in config.yaml if 3000/8080 are in use

**GCP authentication errors:**
- Run: `gcloud auth login` and `gcloud auth application-default login`

**Terraform state issues:**
- Delete `.terraform/` folder and re-run `terraform init`

---

## What's Next?

Once setup is complete:
1. Review `REPO_PLANS.md` for implementation details
2. Start building Phase 1 (core `make dev` command)
3. Test with example app (Repo B)

**Estimated Time to First Working Build:** 1-2 hours (after setup)

---

## System Requirements

- **macOS**: 12 (Monterey) or later
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB free space
- **Network**: Stable internet connection

---

**Setup Complete!** 🎉 You're ready to build the Zero-to-Running tool.
