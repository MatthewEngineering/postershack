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
# The actual Docker image is written by CI/CD via `az containerapp update`
# after each build, so the placeholder image below is only used on first apply.

resource "azurerm_container_app" "app" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.postershack.name
  revision_mode                = "Single"

  secret {
    name  = "hf-token"
    value = var.hf_token
  }

  template {
    min_replicas = 0
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = var.scale_out_concurrent_requests
    }

    container {
      name   = var.app_name
      image  = "ghcr.io/matthewengineering/postershack/postershack-api:latest"
      cpu    = 1.0
      memory = "2Gi"

      env {
        name        = "HF_TOKEN"
        secret_name = "hf-token"
      }
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
