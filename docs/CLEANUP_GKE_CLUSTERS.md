# How to Clean Up GKE Clusters

## Problem
You're hitting GCP quota limits for IP addresses. Each GKE cluster uses multiple IP addresses (for nodes, LoadBalancers, etc.), and you've reached your limit of 8 addresses in us-central1.

## Solution: Delete Existing Clusters

### Option 1: List All Clusters (to see what exists)

```bash
# List all clusters in us-central1
gcloud container clusters list --region=us-central1

# Or list clusters in all regions
gcloud container clusters list
```

### Option 2: Delete Clusters via gcloud CLI

```bash
# Delete a specific cluster
gcloud container clusters delete CLUSTER_NAME \
    --region=us-central1 \
    --project=YOUR_GCP_PROJECT_ID

# Example:
gcloud container clusters delete example-hello-app-cluster \
    --region=us-central1 \
    --project=your-project-id
```

**Note:** This will take 5-10 minutes. The `--quiet` flag skips confirmation:

```bash
gcloud container clusters delete CLUSTER_NAME \
    --region=us-central1 \
    --project=YOUR_GCP_PROJECT_ID \
    --quiet
```

### Option 3: Delete via Terraform (if you have the terraform state)

If you deployed with Terraform and have the state files:

```bash
cd example-hello-app/terraform  # or wherever your terraform directory is
terraform destroy
```

### Option 4: Delete via GCP Console (Web UI)

1. Go to: https://console.cloud.google.com/kubernetes/clusters
2. Select your project
3. Find the cluster(s) you want to delete
4. Click the three dots menu → Delete
5. Confirm deletion

## Check What's Using IP Addresses

```bash
# List all reserved IP addresses in the region
gcloud compute addresses list --regions=us-central1

# List LoadBalancer services (these reserve IPs)
gcloud compute forwarding-rules list --regions=us-central1
```

## Quick Cleanup Script

If you want to delete all clusters in a region:

```bash
#!/bin/bash
REGION="us-central1"
PROJECT_ID="your-gcp-project-id"

# List clusters
echo "Listing clusters in $REGION..."
gcloud container clusters list --region=$REGION --project=$PROJECT_ID

# Delete each cluster
for cluster in $(gcloud container clusters list --region=$REGION --project=$PROJECT_ID --format="value(name)"); do
    echo "Deleting cluster: $cluster"
    gcloud container clusters delete $cluster \
        --region=$REGION \
        --project=$PROJECT_ID \
        --quiet
done

echo "Done! IP addresses should be freed up in a few minutes."
```

## After Deletion

- IP addresses are released immediately, but quota updates may take a few minutes
- Wait 2-3 minutes after deletion before trying to create a new cluster
- You can verify quota with: `gcloud compute project-info describe --project=YOUR_PROJECT_ID`

## Prevention

- Delete clusters when you're done testing
- Use HTTP LoadBalancer mode (uses fewer IPs than HTTPS with Ingress)
- Consider using a different region if you need more clusters
- Request a quota increase from GCP if you need more IP addresses

