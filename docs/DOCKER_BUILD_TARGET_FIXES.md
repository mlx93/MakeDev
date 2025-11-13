# Docker Build Target & Sync Mechanism Fixes

**Date:** November 12, 2025  
**Issue:** Backend containers building with production stage instead of development stage  
**Status:** ✅ **RESOLVED**

---

## Problem Summary

### Root Cause
1. **Docker build target not configured**: `docker-compose.yml` didn't specify which build stage to use, causing Docker to default to the last stage (production)
2. **Dockerfile sync not working**: Subdirectories weren't getting updated Dockerfiles from parent repository
3. **TypeScript compilation issue**: Production Dockerfile used `npx tsc` which resolved to wrong package (`tsc@2.0.4` instead of TypeScript compiler)

### Symptoms
- Backend containers failing with: `Error: Cannot find module '/app/backend/dist/index.js'`
- Build logs showing `[backend prod 1/11]` instead of `[backend dev 1/8]`
- Subdirectories had outdated `docker-compose.yml` files missing the `target:` line
- Redundant sync messages cluttering output

---

## Changes Implemented

### 1. Docker Build Target Configuration

**Problem:** Docker Compose wasn't using the correct build stage for local development.

**Solution:**
- Added `target: ${DOCKER_BUILD_TARGET:-dev}` to `docker-compose.yml` for both backend and frontend services
- Created `.env` file approach in `setup-local.sh` to set `DOCKER_BUILD_TARGET=dev` before builds
- Environment variable defaults to `dev` if not set, ensuring local dev always uses dev stage

**Files Modified:**
- `docker/docker-compose.yml` - Added `target: ${DOCKER_BUILD_TARGET:-dev}` to backend and frontend builds
- `scripts/setup-local.sh` - Creates `.env` file with `DOCKER_BUILD_TARGET=dev` before docker-compose commands

**Result:**
- `make dev` → Uses `dev` stage (hot reload with `npx tsx watch`)
- `make deploy` → Uses `prod` stage (compiled production builds via `deploy-gke.sh`)

---

### 2. Dockerfile Sync Mechanism

**Problem:** Subdirectories weren't getting updated Dockerfiles from parent repository, causing them to use outdated configurations.

**Solution:**
- Created `sync_dockerfiles()` helper function in `dev-subdir.sh`
- Function checks if files differ before copying (using `cmp`)
- Special check for `docker-compose.yml`: verifies `target:` line exists, syncs if missing
- Sync happens at multiple points: after copying docker directory, before builds, when infrastructure exists
- Function handles missing files gracefully (checks existence before comparing)

**Files Modified:**
- `scripts/dev-subdir.sh` - Added `sync_dockerfiles()` function, consolidated all sync logic
- `scripts/setup-local.sh` - Added explicit docker-compose.yml sync before builds with target line checking
- `scripts/bootstrap.sh` - Added Dockerfile sync after copying infrastructure

**Key Features:**
- Only reports when files actually change: `🔄 Updated Dockerfiles from parent`
- Silent when files are already up to date
- Checks for `target:` line existence in docker-compose.yml
- Handles missing files gracefully

---

### 3. Fixed TypeScript Compilation

**Problem:** Production Dockerfile used `npx tsc` which resolved to wrong package (`tsc@2.0.4` instead of TypeScript compiler).

**Solution:**
- Changed from `RUN npx tsc` to `RUN ./node_modules/.bin/tsc`
- Added TypeScript installation step before compilation: `RUN npm install --no-save typescript @types/node @types/express @types/cors @types/bcrypt @types/jsonwebtoken`
- Added `COPY backend/tsconfig.json ./` step before compilation

**Files Modified:**
- `docker/Dockerfile.backend` - Fixed production stage TypeScript compilation
- `scaffold-templates/root/docker/Dockerfile.backend` - Updated template with fix

**Result:**
- Production builds now correctly compile TypeScript to JavaScript
- Uses locally installed TypeScript compiler instead of resolving wrong package

---

### 4. Consolidated Sync Messages

**Problem:** Redundant sync messages cluttering output (multiple "Synced Dockerfile.backend" messages).

**Solution:**
- Consolidated all sync logic into single `sync_dockerfiles()` function
- Only shows message when files actually change
- Single message: `🔄 Updated Dockerfiles from parent` (only when files differ)
- Silent when files are already up to date

**Result:**
- Clean, minimal output
- Only shows sync messages when necessary

---

## Technical Details

### How Build Targets Work

**Local Development (`make dev`):**
```yaml
# docker-compose.yml
backend:
  build:
    target: ${DOCKER_BUILD_TARGET:-dev}  # Defaults to 'dev'
```

```bash
# scripts/setup-local.sh creates .env file
echo "DOCKER_BUILD_TARGET=dev" > docker/.env
```

**Result:**
- Backend runs: `npx tsx watch src/index.ts` (hot reload)
- Frontend runs: `npm run dev` (Vite dev server)
- Volume mounts enabled for live code changes

**Production Deployment (`make deploy`):**
```bash
# scripts/deploy-gke.sh uses direct docker build
docker build --target prod -f docker/Dockerfile.backend ...
```

**Result:**
- Backend runs: `node dist/index.js` (compiled JavaScript)
- Frontend serves: Static files via nginx
- No volume mounts, everything baked into images

---

### Sync Function Logic

```bash
sync_dockerfiles() {
    # Checks if files differ before copying
    # Special check for docker-compose.yml: verifies target: line exists
    # Only copies if files differ or target line missing
    # Returns success even if nothing updated
}
```

**Sync Points:**
1. After copying docker directory (in `dev-subdir.sh`)
2. After bootstrap.sh runs (in `dev-subdir.sh`)
3. When docker directory exists (in `dev-subdir.sh`)
4. Before Docker builds (in `setup-local.sh`)

---

## Files Changed Summary

### Core Scripts
- `scripts/dev-subdir.sh` - Added sync_dockerfiles() function, consolidated sync logic
- `scripts/setup-local.sh` - Added .env file creation, explicit docker-compose.yml sync, DOCKER_BUILD_TARGET handling
- `scripts/bootstrap.sh` - Added Dockerfile sync after copying

### Docker Configuration
- `docker/docker-compose.yml` - Added `target: ${DOCKER_BUILD_TARGET:-dev}` to backend and frontend builds
- `docker/Dockerfile.backend` - Fixed TypeScript compilation (use `./node_modules/.bin/tsc`)

### Templates
- `scaffold-templates/root/docker/Dockerfile.backend` - Updated template with TypeScript compilation fix

### Documentation
- `memory-bank/activeContext.md` - Documented all fixes
- `memory-bank/projectbrief.md` - Updated version to 1.3
- `VIDEO_DEMO_SCRIPT.md` - Updated commentary to clarify dev vs prod builds

---

## Testing & Verification

### Before Fix
- ❌ Backend containers failing: `Error: Cannot find module '/app/backend/dist/index.js'`
- ❌ Build logs showing: `[backend prod 1/11]`
- ❌ Subdirectories had outdated docker-compose.yml files

### After Fix
- ✅ Backend containers start successfully with dev stage
- ✅ Build logs show: `[backend dev 1/8]`
- ✅ Subdirectories automatically get correct docker-compose.yml with target line
- ✅ Clean sync messages (only when files change)
- ✅ Production builds work correctly (TypeScript compiles properly)

---

## Key Takeaways

1. **Build targets are critical**: Docker multi-stage builds need explicit target specification
2. **Sync mechanism must be robust**: Subdirectories must always get latest Dockerfiles from parent
3. **Environment variables**: `.env` file approach is more reliable than export for docker-compose
4. **TypeScript compilation**: Must use local binary (`./node_modules/.bin/tsc`) not `npx tsc`

---

## For Future Reference

**When creating new subdirectories:**
- Dockerfiles are automatically synced from parent
- `.env` file is created with `DOCKER_BUILD_TARGET=dev`
- docker-compose.yml is checked for `target:` line and synced if missing

**When updating Dockerfiles in parent:**
- Subdirectories will automatically sync on next `make dev` run
- Sync happens before builds, ensuring latest fixes are applied
- Force rebuild triggered when Dockerfiles are synced

**Build stage selection:**
- Local dev: Uses `dev` stage (via `.env` file)
- Production: Uses `prod` stage (via `--target prod` in deploy-gke.sh)

---

**Status:** ✅ All issues resolved. System working correctly with proper build target selection and Dockerfile synchronization.

