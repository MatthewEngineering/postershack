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
  value       = "us-central1-docker.pkg.dev/postershack/postershack/app3"
}

output "gcs_bucket_name" {
  description = "GCS bucket name for generated images"
  value       = google_storage_bucket.images.name
}

