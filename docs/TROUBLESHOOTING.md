# Zero-to-Running Developer Environment
## Troubleshooting Guide

**Last Updated:** November 11, 2025

---

## Quick Fixes

### Port Conflicts

**Problem:** Ports 3000, 8080, 5432, or 6379 are already in use.

**Solution:**
The tool automatically frees ports 5432 and 6379 if they're used by Docker containers. For non-Docker services:

```bash
# Find process using port
lsof -i :3000  # or :8080, :5432, :6379

# Stop the process (replace PID with actual process ID)
kill -9 <PID>
```

**Alternative:** Change ports in `config.yaml`:
```yaml
services:
  frontend:
    port: 3001  # Change from 3000
  backend:
    port: 8081  # Change from 8080
```

---

## Docker Issues

### Docker Desktop Not Running

**Symptoms:**
- `Error: Cannot connect to the Docker daemon`
- `docker: command not found`

**Solution:**
1. Open Docker Desktop from Applications
2. Wait for "Docker Desktop is running" in menu bar
3. Verify: `docker ps` should work without errors

**Prevention:**
- Set Docker Desktop to start automatically on login
- Check menu bar icon before running `make dev`

---

### Port Already Allocated

**Symptoms:**
- `Error: port is already allocated`
- Services fail to start

**Solution:**
The tool automatically stops containers using ports 5432 and 6379. If issue persists:

```bash
# Stop all containers
docker stop $(docker ps -q)

# Or stop specific container
docker ps  # Find container name
docker stop <container-name>
```

---

### Container Health Check Failures

**Symptoms:**
- Services show as unhealthy
- Health checks timeout

**Solution:**
1. **Check logs:**
   ```bash
   docker-compose -f <project>/docker/docker-compose.yml logs -f
   ```

2. **Restart services:**
   ```bash
   make destroy SUBDIR=<project>
   make dev SUBDIR=<project>
   ```

3. **Check database connectivity:**
   ```bash
   curl http://localhost:8080/api/v1/health/ready
   ```
   Should return `{"status":"ok"}`

---

## GKE Deployment Issues

### GKE Quota Errors

**Symptoms:**
- `Error: insufficient quota`
- `Error: resource quota exceeded`

**Solution:**
1. **Check quotas:**
   ```bash
   gcloud compute project-info describe --project=<project-id>
   ```

2. **Request quota increase:**
   - Go to GCP Console → IAM & Admin → Quotas
   - Filter by "Compute Engine API"
   - Request increase for "In-use IP addresses" or "CPUs"

3. **Use smaller cluster:**
   ```yaml
   gke:
     node_config:
       node_count: 1  # Reduce from 2
       machine_type: e2-small  # Reduce from e2-medium
   ```

---

### Region Limits

**Symptoms:**
- `Error: zone does not have enough resources`

**Solution:**
1. **Try different region:**
   ```yaml
   gke:
     region: us-east1  # Change from us-central1
   ```

2. **Check available regions:**
   ```bash
   gcloud compute regions list
   ```

---

### Terraform State Errors

**Symptoms:**
- `Error: Backend initialization required`
- `Error: state file not found`

**Solution:**
1. **Reinitialize Terraform:**
   ```bash
   cd <project>/terraform
   terraform init
   ```

2. **If state corrupted:**
   ```bash
   rm -rf .terraform terraform.tfstate*
   terraform init
   ```

---

### kubectl Connection Issues

**Symptoms:**
- `Error: unable to connect to server`
- `Error: context not found`

**Solution:**
1. **Get cluster credentials:**
   ```bash
   gcloud container clusters get-credentials <cluster-name> \
     --region=<region> \
     --project=<project-id>
   ```

2. **Verify connection:**
   ```bash
   kubectl get nodes
   ```

---

### Health Check Failures in GKE

**Symptoms:**
- Pods show as "CrashLoopBackOff"
- Readiness probe failures

**Solution:**
1. **Check pod logs:**
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

2. **Check pod events:**
   ```bash
   kubectl describe pod -n <namespace> <pod-name>
   ```

3. **Verify health endpoints:**
   ```bash
   kubectl exec -n <namespace> <pod-name> -- curl http://localhost:8080/api/v1/health
   ```

---

## Seed Script Issues

### MODULE_NOT_FOUND Errors

**Symptoms:**
- `Error: Cannot find module 'yaml'`
- `Error: Cannot find module '@faker-js/faker'`

**Solution:**
The deployment script automatically installs dependencies. If issue persists:

1. **Check backend dependencies:**
   ```bash
   kubectl exec -n <namespace> <backend-pod> -- \
     sh -c "cd /app/backend && npm list yaml @faker-js/faker"
   ```

2. **Manual installation (if needed):**
   ```bash
   kubectl exec -n <namespace> <backend-pod> -- \
     sh -c "cd /app/backend && npm install --no-save yaml@2.3.4 @faker-js/faker@8.3.1 tsx@4.7.0"
   ```

**Note:** The script has fallback to `/tmp/node_modules` if primary installation fails.

---

### Seed Script Dependency Installation

**Symptoms:**
- Seed script fails during deployment
- Dependencies not found

**Expected Behavior:**
The deployment script automatically installs seed dependencies. You may see:
```
Installing seed script dependencies...
Installing: yaml@2.3.4 @faker-js/faker@8.3.1 tsx@4.7.0
✓ Dependencies installed
```

**If Installation Fails:**
- Script falls back to `/tmp/node_modules`
- Deployment continues (non-blocking)
- Check pod logs for details

---

### Schema Parsing Errors

**Symptoms:**
- `Error: Cannot read Prisma schema`
- `Error: Invalid schema format`

**Solution:**
1. **Verify schema exists:**
   ```bash
   ls <project>/backend/prisma/schema.prisma
   ```

2. **Check schema syntax:**
   ```bash
   cd <project>/backend
   npx prisma validate
   ```

3. **Regenerate Prisma client:**
   ```bash
   npx prisma generate
   ```

---

## HTTP LoadBalancer Mode

### When to Use HTTP Mode

**Use HTTP LoadBalancer mode when:**
- Fast deployment needed (2-5 min vs 10-20 min)
- No custom domain required
- Development/testing environment
- Demo presentations

**How to Enable:**
Comment out `domain_name` in `config.yaml`:
```yaml
gke:
  project_id: "my-gcp-project"
  region: us-central1
  # domain_name: "example.com"  # Commented = HTTP mode
```

---

### HTTPS Mode Issues

**Symptoms:**
- Ingress IP never assigned
- SSL certificate provisioning delays

**Solution:**
1. **Check DNS configuration:**
   - Ensure A record points to LoadBalancer IP
   - Wait for DNS propagation (5-10 minutes)

2. **Check certificate status:**
   ```bash
   kubectl describe certificate -n <namespace>
   ```

3. **Switch to HTTP mode (faster):**
   Comment out `domain_name` in `config.yaml`

---

## Nginx API Proxy Issues

### Frontend Can't Reach Backend

**Symptoms:**
- `405 Method Not Allowed` errors
- Login fails
- API calls return errors

**Solution:**
1. **Verify nginx proxy configuration:**
   - Frontend Dockerfile includes nginx proxy config
   - `/api/*` requests are proxied to `backend-service:8080`

2. **Check backend service:**
   ```bash
   kubectl get svc -n <namespace> backend-service
   ```

3. **Test backend directly:**
   ```bash
   kubectl port-forward -n <namespace> svc/backend-service 8080:8080
   curl http://localhost:8080/api/v1/health
   ```

---

### 405 Errors on API Calls

**Symptoms:**
- `405 Method Not Allowed` on POST requests
- Frontend can't authenticate

**Root Cause:**
Nginx proxy not configured or backend service not accessible.

**Solution:**
1. **Rebuild frontend image:**
   ```bash
   make deploy SUBDIR=<project>
   ```
   This ensures nginx proxy configuration is included.

2. **Verify proxy config in frontend pod:**
   ```bash
   kubectl exec -n <namespace> <frontend-pod> -- cat /etc/nginx/nginx.conf | grep -A 10 "location /api"
   ```

---

## Dynamic Namespace Issues

### Namespace Conflicts

**Symptoms:**
- `Error: namespace already exists`
- Resources deployed to wrong namespace

**Solution:**
1. **Check existing namespaces:**
   ```bash
   kubectl get namespaces
   ```

2. **Use different project name:**
   ```yaml
   project:
     name: different-project-name  # Changes namespace
   ```

3. **Clean up old namespace:**
   ```bash
   kubectl delete namespace <old-namespace>
   ```

---

### Namespace Cleanup

**To remove all resources in a namespace:**
```bash
kubectl delete namespace <namespace-name>
```

**Warning:** This deletes all resources in the namespace. Use `make destroy` for safe cleanup.

---

## GitHub CLI Issues

### Authentication Errors

**Symptoms:**
- `Error: authentication required`
- `Error: gh: command not found`

**Solution:**
1. **Install GitHub CLI (macOS):**
   ```bash
   brew install gh
   ```

2. **Authenticate:**
   ```bash
   gh auth login
   ```
   Follow prompts to authenticate via browser.

3. **Verify authentication:**
   ```bash
   gh auth status
   ```

---

### Repository Creation Failures

**Symptoms:**
- `Error: repository already exists`
- `Error: failed to create repository`

**Solution:**
1. **Check if repo exists:**
   ```bash
   gh repo view <username>/<repo-name>
   ```

2. **Use different project name:**
   ```yaml
   project:
     name: different-name  # Changes repo name
   ```

3. **Delete existing repo (if safe):**
   ```bash
   gh repo delete <username>/<repo-name> --yes
   ```

---

## Cleanup Procedures

### Reset Local Environment

**To completely reset a project:**
```bash
make destroy SUBDIR=<project>
rm -rf <project>
```

**To reset without destroying:**
```bash
cd <project>
docker-compose -f docker/docker-compose.yml down -v
```

---

### Reset GKE Deployment

**To destroy GKE resources:**
```bash
make destroy SUBDIR=<project>
```

**To destroy cluster (if not reused):**
```bash
cd <project>/terraform
terraform destroy
```

**Warning:** This permanently deletes all resources. Ensure you have backups if needed.

---

## Common Error Messages

### "Docker daemon not running"
**Fix:** Open Docker Desktop, wait for "running" status

### "Port already allocated"
**Fix:** Stop conflicting containers or change ports in config.yaml

### "Cannot connect to database"
**Fix:** Check PostgreSQL container is running: `docker ps | grep postgres`

### "Health check failed"
**Fix:** Check service logs: `docker-compose logs <service-name>`

### "Insufficient quota"
**Fix:** Request quota increase in GCP Console or reduce cluster size

### "Terraform state locked"
**Fix:** Wait a few minutes or manually unlock: `terraform force-unlock <lock-id>`

---

## Getting More Help

1. **Check Documentation:**
   - `README.md` - Main documentation
   - `DEMO_RUNBOOK.md` - Demo guide with expected outputs
   - `PRE_DEPLOYMENT_CHECKLIST.md` - GCP setup guide

2. **Check Logs:**
   - Local: `docker-compose logs -f`
   - GKE: `kubectl logs -n <namespace> <pod-name>`

3. **Open an Issue:**
   - GitHub Issues: https://github.com/wander/zero-to-running-dev-env/issues

---

**Last Updated:** November 11, 2025

