variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "vm_admin_username" {
  description = "Username for the VM"
  type        = string
  sensitive   = true
}

variable "ssh_key_file" {
  description = "SSH public key file"
  type        = string
}

variable "ssh_private_key_file" {
  description = "SSH private key file"
  type        = string
}

variable "currrent_user_object_id" {
  description = "User ID"
  type        = string
}

variable "deployment_visibility" {
  description = "Deployment visibility"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}

locals {
  resource_group_name                = "${var.prefix}-rg"
  infrastructure_resource_group_name = "${var.prefix}-infra-rg"
  sftp_port                          = 4422
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6.3"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

module "ssh" {
  source              = "./modules/ssh"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ssh_key_file        = var.ssh_key_file
}

# module "vnet_onprem" {
#   source              = "./modules/vnet/onprem"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = var.tags
# }

module "vnet_cloud" {
  source              = "./modules/vnet/cloud"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# module "vnet_peering" {
#   source              = "./modules/vnet/peering"
#   vnet_onprem_name    = module.vnet_onprem.name
#   vnet_onprem_id      = module.vnet_onprem.id
#   vnet_cloud_name     = module.vnet_cloud.name
#   vnet_cloud_id       = module.vnet_cloud.id
#   resource_group_name = azurerm_resource_group.rg.name
# }

module "aks_identity" {
  source              = "./modules/identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  identity_name       = "${var.prefix}-aks-identity"
}

module "kubelet_identity" {
  source              = "./modules/identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  identity_name       = "${var.prefix}-kubelet-identity"
}

module "acr" {
  source              = "./modules/acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  prefix              = var.prefix
}

module "role_assign_aks_identity_managed_identity_operator" {
  source               = "./modules/role-assign"
  scope                = module.aks_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.kubelet_identity.principal_id
}

module "role_assign_aks_identity_acr" {
  source               = "./modules/role-assign"
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.kubelet_identity.principal_id
}

module "kv" {
  source              = "./modules/kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
}

module "role_assign_kubelet_identity_kv" {
  source               = "./modules/role-assign"
  scope                = module.kv.kv_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.aks_identity.principal_id
}

module "aks" {
  source                     = "./modules/aks"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = var.tags
  vm_size                    = "standard_d2plds_v5"
  aks_identity_id            = module.aks_identity.id
  kubelet_identity_id        = module.kubelet_identity.id
  kubelet_identity_client_id = module.kubelet_identity.client_id
  kubelet_identity_object_id = module.kubelet_identity.principal_id
  ssh_key_file               = var.ssh_key_file
  admin_username             = var.vm_admin_username
}

module "app_insights" {
  prefix              = var.prefix
  source              = "./modules/monitor/app-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
