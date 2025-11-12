# Auto-Update Old Default Region Fix

## Problem

When the default region was changed from `us-central1` to `us-east1`, existing `config.yaml` files still had `region: "us-central1"` hardcoded. When users ran `make deploy`:

1. `deploy-gke.sh` read the old region from `config.yaml` (us-central1)
2. It displayed the old region in the output
3. It used the old region for deployment (causing quota errors)
4. Even when `setup-config.sh` ran and user accepted defaults, the old region was already read and displayed

## Root Cause

The flow was:
1. `deploy-gke.sh` reads config.yaml → gets `us-central1`
2. `deploy-gke.sh` displays "Region: us-central1"
3. `deploy-gke.sh` checks if project_id is missing → if yes, runs `setup-config.sh`
4. `setup-config.sh` writes new default (`us-east1`) to config.yaml
5. But `deploy-gke.sh` already read the old value and displayed it

The issue: `deploy-gke.sh` only checked for missing `project_id`, not for old default region.

## Solution

Updated `scripts/deploy-gke.sh` to:

1. **Read config silently** (before displaying)
2. **Check for old default region** (`us-central1`) in addition to missing `project_id`
3. **Trigger `setup-config.sh`** if either condition is met
4. **Re-read config** after `setup-config.sh` completes
5. **Then display** the updated configuration

### Changes Made

**In `scripts/deploy-gke.sh`:**
- Moved config reading before display
- Added check: `if [ "$GCP_REGION" = "us-central1" ]`
- Triggers `setup-config.sh` to update to new default (`us-east1`)
- Re-reads config after update
- Displays updated config (now shows `us-east1`)

## How It Works Now

1. **User runs `make deploy`** with old config (`region: us-central1`)
2. **`deploy-gke.sh` reads config** silently
3. **Detects old default**: `region = us-central1`
4. **Shows warning**: "Region is set to old default (us-central1)"
5. **Runs `setup-config.sh`** interactively
6. **User accepts defaults** → `setup-config.sh` writes `us-east1`
7. **`deploy-gke.sh` re-reads config** → now has `us-east1`
8. **Displays updated config**: "Region: us-east1"
9. **Deploys to `us-east1`** ✅

## Result

- ✅ **Automatic detection** of old default region
- ✅ **Automatic update** to new default when user accepts defaults
- ✅ **No manual config editing** required
- ✅ **Prevents quota errors** by using `us-east1` instead of `us-central1`

## Testing

To test:
1. Create a config.yaml with `region: "us-central1"`
2. Run `make deploy`
3. Should detect old region and prompt for update
4. Accept defaults → should update to `us-east1`
5. Deployment should use `us-east1`

## Files Modified

- `scripts/deploy-gke.sh` - Added old region detection and auto-update logic

