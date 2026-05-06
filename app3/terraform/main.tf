terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Artifact Registry: GHCR remote proxy ──────────────────────────────────────
# Cloud Run can only pull from Artifact Registry. This remote repo proxies GHCR
# so you keep pushing to GHCR and GCP fetches through here automatically.

resource "google_artifact_registry_repository" "ghcr_proxy" {
  location      = var.region
  repository_id = "ghcr-proxy"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }

    upstream_credentials {
      username_password_credentials {
        username                = var.ghcr_username
        password_secret_version = google_secret_manager_secret_version.ghcr_pat.id
      }
    }
  }
}

# ── GCS bucket (replaces Azure Blob Storage) ──────────────────────────────────

resource "google_storage_bucket" "images" {
  name          = "${var.project_id}-postershack-images"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 90 }
    action { type = "Delete" }
  }
}

# ── Secrets ───────────────────────────────────────────────────────────────────

resource "google_secret_manager_secret" "ghcr_pat" {
  secret_id = "ghcr-pat"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ghcr_pat" {
  secret      = google_secret_manager_secret.ghcr_pat.id
  secret_data = var.ghcr_pat
}

resource "google_secret_manager_secret" "hf_token" {
  secret_id = "hf-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "hf_token" {
  secret      = google_secret_manager_secret.hf_token.id
  secret_data = var.hf_token
}

# ── Service accounts ──────────────────────────────────────────────────────────

resource "google_service_account" "cloud_run" {
  account_id   = "${var.app_name}-cr"
  display_name = "Cloud Run runtime SA for ${var.app_name}"
}

resource "google_service_account" "github_actions" {
  account_id   = "${var.app_name}-gh"
  display_name = "GitHub Actions deploy SA for ${var.app_name}"
}

# ── IAM: Cloud Run SA ─────────────────────────────────────────────────────────

resource "google_artifact_registry_repository_iam_member" "cloud_run_reader" {
  repository = google_artifact_registry_repository.ghcr_proxy.name
  location   = google_artifact_registry_repository.ghcr_proxy.location
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_secret_manager_secret_iam_member" "cloud_run_hf_token" {
  secret_id = google_secret_manager_secret.hf_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_storage" {
  bucket = google_storage_bucket.images.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.cloud_run.email}"
}

# ── IAM: GitHub Actions SA (Workload Identity Federation) ────────────────────

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "github_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# GitHub Actions needs to act as the Cloud Run SA when deploying.
resource "google_service_account_iam_member" "github_act_as_cr" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

# ── Cloud Run service ─────────────────────────────────────────────────────────
# Terraform owns infrastructure: scaling, ingress, env wiring, service account.
# Image tag is updated by the CI/CD deploy action on each push.

resource "google_cloud_run_v2_service" "app" {
  name     = var.app_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run.email

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      # Placeholder — CI/CD overwrites the tag on first push.
      image = "${var.region}-docker.pkg.dev/${var.project_id}/ghcr-proxy/matthewengineering/postershack/postershack-api:latest"

      ports {
        container_port = 7860
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
