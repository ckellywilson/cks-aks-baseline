
variable "location" {
  type    = string
  default = "eastus"

}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

resource "random_string" "kv_name" {
  length  = 8
  special = false
}

resource "azurerm_key_vault" "kv" {
  name                      = "kv-${random_string.kv_name.result}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = var.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  # access_policy {
  #   tenant_id = var.tenant_id
  #   object_id = var.user_managed_principal_id

  #   key_permissions = [
  #     "Get",
  #     "List",
  #     "Update",
  #     "Create",
  #     "Delete"
  #   ]

  #   secret_permissions = [
  #     "Get",
  #     "List",
  #     "Set",
  #     "Recover",
  #     "Delete"
  #   ]

  #   certificate_permissions = [
  #     "Get",
  #     "List",
  #     "Update",
  #     "Recover",
  #     "Delete"
  #   ]
  # }

  # access_policy {
  #   tenant_id = var.tenant_id
  #   object_id = var.currrent_user_object_id

  #   key_permissions = [
  #     "Get",
  #     "List",
  #     "Update",
  #     "Create",
  #     "Delete"
  #   ]

  #   secret_permissions = [
  #     "Get",
  #     "List",
  #     "Set",
  #     "Recover",
  #     "Delete"
  #   ]

  #   certificate_permissions = [
  #     "Get",
  #     "List",
  #     "Update",
  #     "Recover",
  #     "Delete"
  #   ]
  # }

  tags = {
    environment = "Production"
  }
}

output "kv_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "kv_name" {
  value = azurerm_key_vault.kv.name
}

output "kv_id" {
  value = azurerm_key_vault.kv.id
}
