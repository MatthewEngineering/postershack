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
