terraform {
  required_version = ">= 1.5"

  # After first apply, uncomment this block and run: terraform init -migrate-state
  # backend "gcs" {
  #   bucket = "postershack-tfstate"
  #   prefix = "app3/terraform/state"
  # }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  project_id = "postershack"
  region     = "us-central1"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

# ── APIs ──────────────────────────────────────────────────────────────────────

resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

# ── Artifact Registry ─────────────────────────────────────────────────────────

resource "google_artifact_registry_repository" "images" {
  location      = local.region
  repository_id = "postershack"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# ── GCS bucket ────────────────────────────────────────────────────────────────

resource "google_storage_bucket" "tfstate" {
  name          = "postershack-tfstate"
  location      = local.region
  force_destroy = false

  uniform_bucket_level_access = true
  versioning { enabled = true }
}

resource "google_storage_bucket" "images" {
  name          = "${local.project_id}-images"
  location      = local.region
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 90 }
    action { type = "Delete" }
  }
}

# ── Secrets ───────────────────────────────────────────────────────────────────

resource "google_secret_manager_secret" "hf_token" {
  secret_id  = "hf-token"
  depends_on = [google_project_service.apis]
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "hf_token" {
  secret      = google_secret_manager_secret.hf_token.id
  secret_data = var.hf_token
}

# ── Cloud Run service ─────────────────────────────────────────────────────────

resource "google_cloud_run_v2_service" "app" {
  name                = var.app_name
  location            = local.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  depends_on          = [google_project_service.apis]

  template {

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      # Placeholder — CI/CD overwrites this on first push.
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      ports {
        container_port = 7860
      }

      env {
        name  = "PORT"
        value = "7860"
      }

      env {
        name  = "GRADIO_SERVER_NAME"
        value = "0.0.0.0"
      }

      env {
        name  = "GRADIO_SERVER_PORT"
        value = "7860"
      }

      env {
        name  = "STORAGE_MODE"
        value = "gcs"
      }

      env {
        name  = "GCS_BUCKET_NAME"
        value = google_storage_bucket.images.name
      }

      env {
        name = "HF_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.hf_token.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
