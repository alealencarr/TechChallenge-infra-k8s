variable "resource_group_name" {
  type        = string
  description = "O nome do grupo de recursos onde a infra de computação será criada."
  default     = "rg-tchungry-prod"
}

variable "location" {
  type        = string
  description = "A região do Azure onde os recursos serão criados."
  default     = "Brazil South"
}

variable "cluster_name" {
  type        = string
  description = "O nome do cluster Kubernetes (AKS)."
  default     = "aks-tchungry-prod"
}

variable "acr_name" {
  type        = string
  description = "O nome do Azure Container Registry."
  default     = "acrtchungryprod"
}

variable "function_app_name" {
  type        = string
  description = "O nome da Function App de autenticação."
  default     = "func-tchungry-auth"
}

variable "vnet_name" {
  type        = string
  description = "O nome da Rede Virtual principal."
  default     = "vnet-tchungry-prod"
}

variable "aks_subnet_name" {
  type        = string
  description = "O nome da sub-rede onde o AKS será implantado."
  default     = "snet-aks"
}

variable "app_subnet_name" {
  type        = string
  description = "O nome da sub-rede de aplicações para o Application Gateway."
  default     = "snet-apps"
}

variable "apim_subnet_name" {
  type        = string
  description = "O nome da sub-rede do APIM."
  default     = "snet-apim"
}

