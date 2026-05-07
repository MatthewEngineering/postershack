variable "app_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "postershack-api"
}

variable "hf_token" {
  description = "HuggingFace API token"
  type        = string
  sensitive   = true
}
