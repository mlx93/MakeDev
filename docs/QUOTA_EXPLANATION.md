# Understanding the IN_USE_ADDRESSES Quota Error

## What Happened

The error `Quota 'IN_USE_ADDRESSES' exceeded. Limit: 8.0` means you hit the limit for IP addresses in the `us-central1` region.

## Why Only 2 Clusters Hit the Limit

**IN_USE_ADDRESSES counts ALL IP addresses**, not just from GKE clusters:

### What Uses IP Addresses:

1. **GKE Cluster Nodes**: Each node gets 1 IP
   - `task-app-cluster`: 6 nodes = **6 IPs**
   - `example-hello-app-cluster`: 3 nodes = **3 IPs** (attempted)

2. **LoadBalancer Services**: Each LoadBalancer gets 1 external IP
   - `task-app-cluster`: 1 LoadBalancer = **1 IP**
   - `example-hello-app-cluster`: 1 LoadBalancer (attempted) = **1 IP**

3. **Other GCP Resources**: 
   - Forwarding rules
   - Static IP addresses
   - VPN gateways
   - Any other resources using IPs in that region

### The Math:

When you tried to create `example-hello-app-cluster`:
- `task-app-cluster` was already using: **6 nodes + 1 LoadBalancer = 7 IPs**
- `example-hello-app-cluster` needed: **3 nodes + 1 LoadBalancer = 4 IPs**
- **Total needed: 11 IPs**
- **Your limit: 8 IPs** ❌

So even though you only had 2 clusters, you needed 11 IPs but only had 8 available!

## The 404 Error

The `example-hello-app-cluster` doesn't exist anymore because:
- The cluster creation **failed partway through**
- GCP cleaned up the partially created cluster
- But some resources (like forwarding rules, IPs) might still be stuck

## Solution: Clean Up Leftover Resources

Since the cluster is gone, we need to clean up any leftover resources:

```bash
# 1. Check for leftover forwarding rules (LoadBalancers)
gcloud compute forwarding-rules list --regions=us-central1

# 2. Check for leftover target pools
gcloud compute target-pools list --regions=us-central1

# 3. Check for leftover instances (nodes that didn't get cleaned up)
gcloud compute instances list --filter="name~gke-example-hello-app" --zones=us-central1-*

# 4. Delete any leftover forwarding rules
gcloud compute forwarding-rules delete RULE_NAME --region=us-central1 --quiet

# 5. Delete any leftover target pools
gcloud compute target-pools delete POOL_NAME --region=us-central1 --quiet
```

## Prevention

1. **Delete clusters when done testing** - Each cluster uses multiple IPs
2. **Use fewer nodes** - Reduce `node_count` in config.yaml (default is 2, but you had 6)
3. **Request quota increase** - GCP allows quota increases for free
4. **Use different regions** - Spread clusters across regions
5. **Use HTTP LoadBalancer mode** - Uses fewer IPs than HTTPS with Ingress

## Current Status

- ✅ `task-app-cluster` is running fine (6 nodes + 1 LoadBalancer = 7 IPs used)
- ❌ `example-hello-app-cluster` failed and was cleaned up
- ⚠️ You have **1 IP remaining** (8 limit - 7 used = 1 available)

To create a new cluster, you'd need to either:
- Delete `task-app-cluster` (frees 7 IPs)
- Reduce nodes in `task-app-cluster` (free up some IPs)
- Request a quota increase

