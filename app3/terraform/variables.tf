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
  default     = "postershack-app3"
}

variable "max_replicas" {
  description = "Maximum replicas to scale out to"
  type        = number
  default     = 1
}

variable "scale_out_concurrent_requests" {
  description = "Concurrent HTTP requests per replica before ACA adds another replica"
  type        = number
  default     = 10
}

variable "hf_token" {
  description = "HuggingFace API token"
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  description = "Globally unique name for the Azure Storage Account (3-24 lowercase alphanumeric)"
  type        = string
  default     = "postershackimages"
}
