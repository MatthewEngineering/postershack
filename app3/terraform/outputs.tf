output "service_url" {
  description = "Public HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "ar_image_base" {
  description = "Artifact Registry image base — must match GitHub Actions GCP_IMAGE_BASE"
  value       = local.ar_image_base
}

output "gcs_bucket_name" {
  description = "GCS bucket name for generated images"
  value       = google_storage_bucket.images.name
}
