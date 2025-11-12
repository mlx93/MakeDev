# Using Different Regions to Avoid Quota Limits

## Why This Works

**Each GCP region has its own quota limits!**

- `us-central1`: 8 IP addresses (currently 8/8 used - 100%)
- `us-east1`: 8 IP addresses (separate quota - likely 0/8 available)
- `us-west1`: 8 IP addresses (separate quota - likely 0/8 available)
- `europe-west1`: 8 IP addresses (separate quota - likely 0/8 available)

By using different regions, you effectively **multiply your capacity**!

## How to Use a Different Region

### Option 1: Set Region in config.yaml

When `make deploy` prompts for GCP settings, choose a different region:

```
Enter GCP region [us-central1]: us-east1
```

Or edit `config.yaml` directly:

```yaml
gke:
  project_id: "your-project-id"
  region: "us-east1"  # Changed from us-central1
  cluster_name: ""
```

### Option 2: Common Regions to Use

**US Regions (Low Latency for US):**
- `us-east1` - South Carolina (recommended)
- `us-west1` - Oregon
- `us-west2` - Los Angeles
- `us-west3` - Salt Lake City
- `us-west4` - Las Vegas

**Other Regions:**
- `europe-west1` - Belgium
- `europe-west4` - Netherlands
- `asia-southeast1` - Singapore

## Example: Deploy Hello World App to Different Region

```bash
# 1. Run make deploy
make deploy SUBDIR=example-hello-app

# 2. When prompted for region, enter:
Enter GCP region [us-central1]: us-east1

# 3. Continue with deployment
# The cluster will be created in us-east1 with its own 8 IP quota
```

## Benefits

✅ **No quota increase needed** - Use existing quotas in other regions  
✅ **No waiting** - Immediate solution  
✅ **Better redundancy** - Clusters in different regions  
✅ **Same performance** - US regions have similar latency  

## Current Setup

- **task-app-cluster**: `us-central1` (using 7-8 IPs)
- **example-hello-app**: Deploy to `us-east1` (fresh 8 IP quota)

## Regional Considerations

**Latency:**
- `us-east1` vs `us-central1`: Minimal difference for most US users
- Both are excellent choices for US-based applications

**Cost:**
- Same pricing across US regions
- No additional cost for using different regions

**Best Practice:**
- Use `us-east1` or `us-west1` as alternatives to `us-central1`
- All three have similar performance and pricing

## Quick Command Reference

```bash
# Deploy to us-east1 instead
make deploy SUBDIR=example-hello-app
# When prompted: Enter GCP region [us-central1]: us-east1
```

This is actually a **better solution** than requesting a quota increase - it's immediate and gives you more flexibility!

