variable "prefix" {
  description = "A prefix to add to the beginning of the generated resource names."
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the user assigned identity."
}

variable "location" {
  description = "The location/region where the user assigned identity should be created."
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

resource "azurerm_user_assigned_identity" "user_managed_identity" {
  name                = "${var.prefix}-kubelet-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "id" {
  description = "The ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.user_managed_identity.id
}

output "client_id" {
  description = "The Client ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.user_managed_identity.client_id
}

output "principal_id" {
  description = "The Principal ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.user_managed_identity.principal_id
}
