# resource "azurerm_user_assigned_identity" "example" {
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location

#   name = "azfunction"
# }

# resource "azurerm_role_assignment" "example" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Reader"
#   principal_id         = data.azurerm_client_config.example.object_id
# }