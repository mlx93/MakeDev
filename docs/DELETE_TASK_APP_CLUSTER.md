# Delete task-app-cluster

## Command

```bash
gcloud container clusters delete task-app-cluster \
    --region=us-central1 \
    --quiet
```

## What Happens

- ✅ **Cancels in-progress operations** - The reconciling/resize operation will be cancelled
- ✅ **Deletes the cluster** - All nodes, services, and resources will be removed
- ✅ **Frees IP addresses** - All IPs used by the cluster will be released (~5-8 IPs)
- ⏱️ **Takes 5-10 minutes** - Cluster deletion is not instant

## After Deletion

- All IP addresses will be freed (you'll have 8 available again)
- You can create new clusters without quota issues
- Any apps running on the cluster will be unavailable

## Alternative: Wait for Reconciling to Finish

If you want to keep the cluster but just resize it:

```bash
# Wait for STATUS to change from RECONCILING to RUNNING
gcloud container clusters list --region=us-central1

# Then resize
gcloud container clusters resize task-app-cluster \
    --region=us-central1 \
    --num-nodes=2 \
    --node-pool=task-app-cluster-node-pool \
    --quiet
```

## Recommendation

If you're just testing and don't need the task-app running, **delete it** to free up all IP addresses. You can always redeploy later with `make deploy SUBDIR=task-app`.

