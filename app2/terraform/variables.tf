variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "postershack-rg"
}

variable "app_name" {
  description = "Container App name"
  type        = string
  default     = "diffuser-mvp"
}

variable "ghcr_username" {
  description = "GitHub username or org that owns the GHCR package (e.g. 'matthewengineering')"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Personal Access Token with read:packages scope — pass via TF_VAR_ghcr_token or terraform.tfvars"
  type        = string
  sensitive   = true
}

variable "image_name" {
  description = "Image name in GHCR (repo name, e.g. 'postershack/diffuser-mvp')"
  type        = string
  default     = "postershack/diffuser-mvp"
}

variable "image_tag" {
  description = "Image tag to deploy"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "vCPU allocation per replica (0.25 / 0.5 / 1.0 / 2.0)"
  type        = number
  default     = 1.0
}

variable "memory" {
  description = "Memory allocation per replica (must match cpu tier: 2Gi for 1.0 vCPU)"
  type        = string
  default     = "2Gi"
}

variable "max_replicas" {
  description = "Maximum replicas to scale out to"
  type        = number
  default     = 3
}

variable "scale_out_concurrent_requests" {
  description = "Concurrent HTTP requests per replica before ACA adds another replica"
  type        = number
  default     = 10
}
