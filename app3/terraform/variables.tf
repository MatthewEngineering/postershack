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

variable "storage_account_name" {
  description = "Storage account name required by the Function App (3-24 lowercase alphanumeric)"
  type        = string
  default     = "postershackfnstore"
}

variable "sku_name" {
  description = "App Service Plan SKU (e.g. Y1 for Consumption, EP1/EP2/EP3 for Elastic Premium, P1v3 for Premium v3)"
  type        = string
  default     = "EP1"
}

variable "image_name" {
  description = "Full Docker image name, e.g. ghcr.io/org/postershack-api"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy, e.g. a1b2c3d or latest"
  type        = string
  default     = "latest"
}
