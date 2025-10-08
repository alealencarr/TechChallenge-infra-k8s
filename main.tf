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

# --- Data Sources para obter recursos existentes ---

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

# --- Secção do AKS ---

resource "azurerm_container_registry" "acr" {
  name                = "acrtchungryprod"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "akstchungry"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_E2s_v3"  
    vnet_subnet_id = data.azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

   
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }
}

resource "azurerm_role_assignment" "aks_pull_from_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}


# --- Secção da Function App ---

resource "azurerm_storage_account" "function_storage" {
  name                     = "stauth${replace(var.resource_group_name, "-", "")}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "function_plan" {
  name                = "plan-auth-serverless"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "auth_function" {
  name                       = "func-tchungry-auth"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

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
