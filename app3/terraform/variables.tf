variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "postershack"
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
  description = "GitHub repo in owner/name format"
  type        = string
  default     = "MatthewEngineering/postershack"
}

variable "hf_token" {
  description = "HuggingFace API token"
  type        = string
  sensitive   = true
}
