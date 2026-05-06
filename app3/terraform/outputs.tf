output "service_url" {
  description = "Public HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "gcs_bucket_name" {
  description = "GCS bucket name for generated images"
  value       = google_storage_bucket.images.name
}

output "ar_proxy_base_url" {
  description = "Artifact Registry proxy base URL — prefix your GHCR image path with this when deploying"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ghcr_proxy.repository_id}"
}

output "workload_identity_provider" {
  description = "Workload Identity provider resource name — set as GCP_WORKLOAD_IDENTITY_PROVIDER secret in GitHub"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  description = "GitHub Actions service account email — set as GCP_SA_EMAIL secret in GitHub"
  value       = google_service_account.github_actions.email
}

output "app_fqdn" {
  description = "Bare FQDN to use as the CNAME target in Spaceship"
  value       = azurerm_container_app.app.latest_revision_fqdn
}

output "custom_domain_verification_id" {
  description = "Value for the TXT record: asuid.postershack-api.matthewengineering.com"
  value       = azurerm_container_app.app.custom_domain_verification_id
  sensitive = true
}
