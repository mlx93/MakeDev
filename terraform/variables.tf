# Terraform Variables for GKE Cluster Provisioning

variable "gcp_project_id" {
  description = "GCP Project ID (required)"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for nodes (cost-conscious default)"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size for each node (GB)"
  type        = number
  default     = 20
}

