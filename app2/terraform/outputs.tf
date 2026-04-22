output "app_url" {
  description = "Public HTTPS URL of the Container App"
  value       = "https://${azurerm_container_app.diffuser.ingress[0].fqdn}"
}

