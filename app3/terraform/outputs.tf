output "app_url" {
  description = "Public HTTPS URL of the Container App"
  value       = "https://${azurerm_container_app.app.latest_revision_fqdn}"
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
