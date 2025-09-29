variable "resource_group_name" {
  type        = string
  description = "O nome do grupo de recursos onde o AKS será criado."
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