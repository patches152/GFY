resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  address_prefixes     = [var.subnet_cidr]
  virtual_network_name = var.vnet_name
#  service_endpoints    = ["Microsoft.Sql"]
}