output "app_url" {
  description = "Public HTTPS URL of the Container App"
  value       = "https://${azurerm_container_app.diffuser.ingress[0].fqdn}"
}

output "image_ref" {
  description = "Full GHCR image reference being deployed"
  value       = "ghcr.io/${var.ghcr_username}/${var.image_name}:${var.image_tag}"
}
