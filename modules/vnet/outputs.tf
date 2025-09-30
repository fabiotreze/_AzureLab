# VNet Module Outputs - Standardized format

# Virtual Network
output "vnet" {
  description = "Virtual Network with standardized information"
  value = {
    name                = azurerm_virtual_network.vnet.name
    id                  = azurerm_virtual_network.vnet.id
    location            = azurerm_virtual_network.vnet.location
    resource_group_name = azurerm_virtual_network.vnet.resource_group_name
    address_space       = azurerm_virtual_network.vnet.address_space
    dns_servers         = azurerm_virtual_network.vnet.dns_servers
  }
}

# Legacy outputs for backward compatibility
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

# Subnets
output "subnets" {
  description = "Map of subnets with standardized information"
  value = {
    for k, subnet in azurerm_subnet.subnets : k => {
      name                = subnet.name
      id                  = subnet.id
      location            = azurerm_virtual_network.vnet.location
      resource_group_name = subnet.resource_group_name
      address_prefixes    = subnet.address_prefixes
      virtual_network_name = subnet.virtual_network_name
    }
  }
}

# Legacy subnet outputs for backward compatibility
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "Map of subnet names to their full names"
  value       = { for k, v in azurerm_subnet.subnets : k => v.name }
}

# Network Security Groups
output "nsgs" {
  description = "Map of NSGs with standardized information"
  value = {
    for k, nsg in azurerm_network_security_group.nsg : k => {
      name                = nsg.name
      id                  = nsg.id
      location            = nsg.location
      resource_group_name = nsg.resource_group_name
    }
  }
}

# Legacy NSG outputs for backward compatibility
output "nsg_ids" {
  description = "Map of subnet names to their NSG IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "nsg_names" {
  description = "Map of subnet names to their NSG names"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.name }
}