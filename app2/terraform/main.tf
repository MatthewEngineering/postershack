terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# ── Resource Group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "postershack" {
  name     = var.resource_group_name
  location = var.location
}

# ── Container Apps Environment ────────────────────────────────────────────────

resource "azurerm_container_app_environment" "env" {
  name                = "${var.app_name}-env"
  resource_group_name = azurerm_resource_group.postershack.name
  location            = azurerm_resource_group.postershack.location
}

# ── Container App ─────────────────────────────────────────────────────────────
# Terraform owns infrastructure only: scaling rules and ingress config.
# Image, registry auth, and env vars are managed by the CI/CD deploy action.

resource "azurerm_container_app" "diffuser" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.postershack.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = var.scale_out_concurrent_requests
    }

    # Placeholder image — CI/CD deploy action overwrites this on first push.
    container {
      name   = var.app_name
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 1.0
      memory = "2Gi"
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 7860
    allow_insecure_connections = false

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
