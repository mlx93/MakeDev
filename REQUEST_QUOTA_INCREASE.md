# Request IN_USE_ADDRESSES Quota Increase

## Current Situation
- **Current limit**: 8 IP addresses in us-central1
- **Desired limit**: 16 IP addresses
- **Reason**: Need to run multiple GKE clusters for testing

## Option 1: Via GCP Console (Recommended - Easiest)

1. **Go to Quotas page:**
   ```
   https://console.cloud.google.com/iam-admin/quotas?project=YOUR_PROJECT_ID
   ```

2. **Search for quota:**
   - In the search box, type: `IN_USE_ADDRESSES`
   - Filter by region: `us-central1`
   - Filter by service: `Compute Engine API`

3. **Select the quota:**
   - Click on `IN_USE_ADDRESSES` for region `us-central1`

4. **Request increase:**
   - Click "EDIT QUOTAS" button
   - Enter new limit: `16`
   - Provide justification: "Running multiple GKE clusters for development and testing. Each cluster uses 2-4 nodes plus LoadBalancers, requiring more IP addresses."
   - Submit request

5. **Wait for approval:**
   - Usually approved automatically within minutes to hours
   - You'll receive an email when approved

## Option 2: Via gcloud CLI

```bash
# Set your project
PROJECT_ID=$(gcloud config get-value project)

# Request quota increase
gcloud alpha service-usage quotas update IN_USE_ADDRESSES \
    --service=compute.googleapis.com \
    --consumer=projects/$PROJECT_ID \
    --value=16 \
    --dimensions=region=us-central1
```

**Note:** The `gcloud alpha` command may require additional setup. The Console method is more reliable.

## Option 3: Check Current Quota Usage

```bash
# Check current quota and usage
gcloud compute project-info describe \
    --project=$(gcloud config get-value project) \
    --format="yaml(quotas)" | grep -A 3 "IN_USE_ADDRESSES"
```

## What Happens After Approval

- ✅ Quota limit increases to 16
- ✅ You can create more clusters without hitting limits
- ✅ No downtime or service interruption
- ✅ Takes effect immediately after approval

## Typical Approval Time

- **Automatic approval**: Minutes to 2-3 hours (for reasonable requests)
- **Manual review**: 1-2 business days (for very large increases)

## Justification Tips

When requesting, mention:
- "Running multiple GKE clusters for development and testing"
- "Each cluster uses 2-4 nodes plus LoadBalancers"
- "Need capacity for testing different applications simultaneously"
- "Standard development workflow requires multiple environments"

## Alternative: Use Different Regions

If quota increase takes too long, you can:
- Deploy clusters in different regions (e.g., `us-east1`, `us-west1`)
- Each region has its own quota limit
- Spreads your IP usage across regions

## Quick Link

Replace `YOUR_PROJECT_ID` with your actual project ID:
```
https://console.cloud.google.com/iam-admin/quotas?project=YOUR_PROJECT_ID&filter=IN_USE_ADDRESSES
```

