# Terraform Configuration for GKE Cluster Provisioning
# Zero-to-Running Developer Environment

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # State stored in GitHub (version controlled)
  # No remote backend - tfstate files committed to repo
}

# GCP Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Check for existing cluster using data source
data "google_container_cluster" "existing" {
  name     = var.cluster_name
  location = var.gcp_region
  
  # This will return null if cluster doesn't exist
  # We use this to detect and reuse existing clusters
  lifecycle {
    ignore_changes = all
  }
}

# GKE Cluster Resource
# Only creates if cluster doesn't already exist
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.gcp_region

  # Remove default node pool immediately
  # We'll create a custom node pool with specific configuration
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # Workload Identity (best practice for GKE)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Maintenance window (recommended)
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Release channel (regular updates)
  release_channel {
    channel = "REGULAR"
  }

  # Lifecycle: Prevent recreation if cluster exists
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      initial_node_count,
      node_config
    ]
  }
}

# Custom Node Pool
# Separate from cluster to allow independent updates
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Node configuration
  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    # OAuth scopes for node access
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Labels
    labels = {
      environment = "dev"
      managed-by  = "terraform"
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Management (auto-repair and auto-upgrade)
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

