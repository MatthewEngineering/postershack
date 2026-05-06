variable "app_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "postershack-api"
}

variable "max_instances" {
  description = "Maximum Cloud Run instances to scale out to"
  type        = number
  default     = 1
}

variable "hf_token" {
  description = "HuggingFace API token"
  type        = string
  sensitive   = true
}
