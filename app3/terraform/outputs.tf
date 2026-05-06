output "service_url" {
  description = "Public HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_fqdn" {
  description = "Bare FQDN of the Cloud Run service (use as CNAME target)"
  value       = replace(google_cloud_run_v2_service.app.uri, "https://", "")
}

output "ar_image_base" {
  description = "AR image base URL — set as GCP_AR_IMAGE_BASE secret in GitHub"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/postershack/app3"
}

output "gcs_bucket_name" {
  description = "GCS bucket name for generated images"
  value       = google_storage_bucket.images.name
}

output "workload_identity_provider" {
  description = "Workload Identity provider — set as GCP_WORKLOAD_IDENTITY_PROVIDER secret in GitHub"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  description = "GitHub Actions service account email — set as GCP_SA_EMAIL secret in GitHub"
  value       = google_service_account.github_actions.email
}
