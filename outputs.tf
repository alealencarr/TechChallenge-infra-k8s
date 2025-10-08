output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "function_app_default_hostname" {
  description = "A URL base da Function App de autenticação."
  value       = azurerm_linux_function_app.auth_function.default_hostname
}
