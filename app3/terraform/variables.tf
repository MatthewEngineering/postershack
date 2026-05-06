variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "us-central1"
}

variable "app_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "postershack-app3"
}

variable "max_instances" {
  description = "Maximum Cloud Run instances to scale out to"
  type        = number
  default     = 1
}

variable "github_repo" {
  description = "GitHub repo in owner/name format (e.g. MatthewEngineering/postershack)"
  type        = string
  default     = "MatthewEngineering/postershack"
}

variable "ghcr_username" {
  description = "GitHub username for GHCR authentication"
  type        = string
  default     = "MatthewEngineering"
}

variable "ghcr_pat" {
  description = "GitHub Personal Access Token with read:packages scope (used by AR proxy to pull from GHCR)"
  type        = string
  sensitive   = true
}

variable "hf_token" {
  description = "HuggingFace API token"
  type        = string
  sensitive   = true
}
