output "app_url" {
  description = "Public HTTPS URL of the Function App"
  value       = "https://${azurerm_linux_function_app.fn.default_hostname}"
}
