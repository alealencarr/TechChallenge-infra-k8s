output "aks_cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_resource_group" {
  description = "Resource Group do AKS (MC_*)"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "acr_login_server" {
  description = "URL do Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Nome do Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "function_app_name" {
  description = "Nome da Function App"
  value       = azurerm_linux_function_app.auth_function.name
}

output "function_app_default_hostname" {
  description = "Hostname da Function App (para APIM)"
  value       = azurerm_linux_function_app.auth_function.default_hostname
}

output "agic_identity_object_id" {
  description = "Object ID da identidade do AGIC"
  value       = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}