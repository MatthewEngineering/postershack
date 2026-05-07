terraform {
  required_version = ">= 1.5"

  backend "gcs" {
    bucket = "terraform-state-matthewengineering"
    prefix = "postershack/app3/terraform-state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  project_id     = "postershack"
  region         = "us-central1"
  ar_repo        = "postershack"
  image_name     = "postershack-api"
  ar_image_base  = "${local.region}-docker.pkg.dev/${local.project_id}/${local.ar_repo}/${local.image_name}"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

data "google_project" "project" {}

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
  repository_id = local.ar_repo
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# ── GCS bucket ────────────────────────────────────────────────────────────────

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

# ── Secret + access for Cloud Run runtime SA ──────────────────────────────────

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

resource "google_secret_manager_secret_iam_member" "hf_token_accessor" {
  secret_id = google_secret_manager_secret.hf_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# ── Cloud Run service ─────────────────────────────────────────────────────────

resource "google_cloud_run_v2_service" "app" {
  name                = var.app_name
  location            = local.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_iam_member.hf_token_accessor,
  ]

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      # Placeholder — CI/CD overwrites this on first push.
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      ports {
        container_port = 7860
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = local.project_id
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

  # CI/CD owns the image tag — don't let `terraform apply` revert it.
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
