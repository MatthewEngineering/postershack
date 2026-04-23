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

# ── Storage Account (required by Function Apps) ───────────────────────────────

resource "azurerm_storage_account" "fn" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.postershack.name
  location                 = azurerm_resource_group.postershack.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ── App Service Plan (Linux, required for Docker-based Function Apps) ─────────

resource "azurerm_service_plan" "fn" {
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.postershack.name
  location            = azurerm_resource_group.postershack.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

# ── Function App (Docker container) ──────────────────────────────────────────
# Terraform owns infrastructure only: plan, storage, and site config skeleton.
# The actual Docker image is written by CI/CD via `az functionapp config
# container set` after each build, so the placeholder image below is only used
# on first `terraform apply`.

resource "azurerm_linux_function_app" "fn" {
  name                       = var.app_name
  resource_group_name        = azurerm_resource_group.postershack.name
  location                   = azurerm_resource_group.postershack.location
  service_plan_id            = azurerm_service_plan.fn.id
  storage_account_name       = azurerm_storage_account.fn.name
  storage_account_access_key = azurerm_storage_account.fn.primary_access_key

  site_config {
    always_on = var.sku_name != "Y1" # Consumption plan doesn't support always_on

    application_stack {
      docker {
        registry_url = "https://${split("/", var.image_name)[0]}"
        image_name   = join("/", slice(split("/", var.image_name), 1, length(split("/", var.image_name))))
        image_tag    = var.image_tag
      }
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    FUNCTIONS_EXTENSION_VERSION         = "~4"
  }
}
