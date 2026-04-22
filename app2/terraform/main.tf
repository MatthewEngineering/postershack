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

resource "azurerm_container_app" "diffuser" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.postershack.name
  revision_mode                = "Single"

  # GHCR auth — token supplied via TF_VAR_ghcr_token or terraform.tfvars
  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-token"
  }

  secret {
    name  = "ghcr-token"
    value = var.ghcr_token
  }

  template {
    # Scale to zero: 0 min replicas, wake on HTTP traffic
    min_replicas = 0
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = var.scale_out_concurrent_requests
    }

    container {
      name   = var.app_name
      image  = "ghcr.io/${var.ghcr_username}/${var.image_name}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "GRADIO_SERVER_NAME"
        value = "0.0.0.0"
      }
      env {
        name  = "GRADIO_SERVER_PORT"
        value = "7860"
      }
      env {
        name  = "GRADIO_ANALYTICS_ENABLED"
        value = "False"
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
