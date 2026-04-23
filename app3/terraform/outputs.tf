output "app_url" {
  description = "Public HTTPS URL of the Container App"
  value       = "https://${azurerm_container_app.app.latest_revision_fqdn}"
}

output "storage_connection_string" {
  description = "Connection string for the images Storage Account (add to .env)"
  value       = azurerm_storage_account.images.primary_connection_string
  sensitive   = true
}
