terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatetchungryale"
    container_name       = "tfstate"
    key                  = "infra-compute.tfstate" 
  }
}

provider "azurerm" {
  features {}
}

# --- Data Sources ---
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "app_subnet" {
  name                 = var.app_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "apim_subnet" {
  name                 = var.apim_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# --- 1. Azure Container Registry (ACR) ---

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# --- 2. Azure Kubernetes Service (AKS) com AGIC ---

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "akstchungry"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_E2s_v3"  
    vnet_subnet_id = data.azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }
  
  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.240.0.0/16"
    dns_service_ip     = "10.240.0.10"
  }

  # Application Gateway Ingress Controller (AGIC)
  ingress_application_gateway {
    gateway_name = "agw-ingress-tchungry"
    subnet_id    = data.azurerm_subnet.app_subnet.id
  }
}

# --- 3. Permissões do AKS ---

# 3.1. AKS pode puxar imagens do ACR
resource "azurerm_role_assignment" "aks_pull_from_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
  
  # Evita recriar a role assignment desnecessariamente
  skip_service_principal_aad_check = true
}

# 3.2. AGIC pode gerenciar a subnet do Application Gateway
resource "azurerm_role_assignment" "aks_agic_subnet_contributor" {
  scope                = data.azurerm_subnet.app_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# 3.3. AGIC pode gerenciar o Application Gateway
resource "azurerm_role_assignment" "aks_agic_gateway_contributor" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# 3.4. AGIC pode ler configurações da VNET
resource "azurerm_role_assignment" "aks_agic_vnet_reader" {
  scope                = data.azurerm_virtual_network.vnet.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# --- 4. Function App Serverless (Auth) ---

# 4.1. Storage Account para a Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = "stauth${replace(var.resource_group_name, "-", "")}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 4.2. App Service Plan para a Function App
resource "azurerm_service_plan" "function_plan" {
  name                = "plan-auth-serverless"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 4.3. Function App (PRIVADA - só APIM acessa via VNet)
resource "azurerm_linux_function_app" "auth_function" {
  name                       = var.function_app_name
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  #  Function App PRIVADA (só abre temporariamente no deploy via GitHub Actions)
  public_network_access_enabled = false

  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
  }
}

