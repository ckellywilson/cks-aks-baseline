variable "location" {
  description = "The location where the resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "prefix" {
  description = "The prefix for the resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "aks_identity_id" {
  description = "The ID of the User Assigned Identity for AKS"
  type        = string
}

variable "kubelet_identity_id" {
  description = "The ID of the User Assigned Identity for Kubelet"
  type        = string
}

variable "kubelet_identity_client_id" {
  description = "The Client ID of the User Assigned Identity for Kubelet"
  type        = string
}

variable "kubelet_identity_object_id" {
  description = "The Object ID of the User Assigned Identity for Kubelet"
  type        = string
}

variable "vm_size" {
  description = "The size of the VMs in the AKS cluster"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "ssh_key_file" {
  description = "The path to the SSH public key file"
  type        = string
}

variable "admin_username" {
  description = "The username for the admin user"
  type        = string
  default     = "vscode"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks${var.prefix}"

  default_node_pool {
    name       = "system"
    node_count = 3
    vm_size    = var.vm_size
  }

  # linux_profile {
  #   admin_username = var.admin_username
  #   ssh_key {
  #     key_data = file(var.ssh_key_file)
  #   }
  # }

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.aks_identity_id
    ]
  }

  kubelet_identity {
    user_assigned_identity_id = var.kubelet_identity_id
    client_id                 = var.kubelet_identity_client_id
    object_id                 = var.kubelet_identity_id
  }

  network_profile {
    network_plugin      = "azure"
    network_policy      = "azure"
    network_plugin_mode = "overlay"
  }
}
