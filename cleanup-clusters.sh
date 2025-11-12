#!/bin/bash
# Quick script to list and optionally delete GKE clusters

REGION="${1:-us-central1}"
PROJECT_ID="${2:-$(gcloud config get-value project)}"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: GCP project ID not set"
    echo "Usage: $0 [REGION] [PROJECT_ID]"
    echo "Example: $0 us-central1 my-project-id"
    exit 1
fi

echo "🔍 Listing clusters in $REGION for project $PROJECT_ID..."
echo ""

CLUSTERS=$(gcloud container clusters list --region=$REGION --project=$PROJECT_ID --format="value(name)" 2>/dev/null)

if [ -z "$CLUSTERS" ]; then
    echo "✅ No clusters found in $REGION"
    exit 0
fi

echo "Found clusters:"
gcloud container clusters list --region=$REGION --project=$PROJECT_ID
echo ""

read -p "Do you want to delete all these clusters? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

for cluster in $CLUSTERS; do
    echo "🗑️  Deleting cluster: $cluster"
    gcloud container clusters delete $cluster \
        --region=$REGION \
        --project=$PROJECT_ID \
        --quiet 2>&1 | grep -v "INFORMATION:" || echo "   ✅ Deleted (or already gone)"
done

echo ""
echo "✅ Done! IP addresses should be freed up in a few minutes."
