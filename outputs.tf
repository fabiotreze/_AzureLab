# Outputs for the hub-spoke network infrastructure

# Resource Groups
output "resource_group_names" {
  description = "Map of resource group names"
  value       = { for k, rg in azurerm_resource_group.rg : k => rg.name }
}

output "resource_group_locations" {
  description = "Map of resource group locations"
  value       = { for k, rg in azurerm_resource_group.rg : k => rg.location }
}

output "resource_group_ids" {
  description = "Map of resource group IDs"
  value       = { for k, rg in azurerm_resource_group.rg : k => rg.id }
}

# Hub VNet Outputs
output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = module.vnet_hub.vnet_id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = module.vnet_hub.vnet_name
}

output "hub_subnet_ids" {
  description = "Map of hub subnet names to their IDs"
  value       = module.vnet_hub.subnet_ids
}

output "hub_subnet_names" {
  description = "Map of hub subnet names to their full names"
  value       = module.vnet_hub.subnet_names
}

output "hub_nsg_ids" {
  description = "Map of hub subnet names to their NSG IDs"
  value       = module.vnet_hub.nsg_ids
}

# Spoke1 VNet Outputs
output "spoke1_vnet_id" {
  description = "ID of the spoke1 virtual network"
  value       = module.vnet_spoke1.vnet_id
}

output "spoke1_vnet_name" {
  description = "Name of the spoke1 virtual network"
  value       = module.vnet_spoke1.vnet_name
}

output "spoke1_subnet_ids" {
  description = "Map of spoke1 subnet names to their IDs"
  value       = module.vnet_spoke1.subnet_ids
}

output "spoke1_subnet_names" {
  description = "Map of spoke1 subnet names to their full names"
  value       = module.vnet_spoke1.subnet_names
}

output "spoke1_nsg_ids" {
  description = "Map of spoke1 subnet names to their NSG IDs"
  value       = module.vnet_spoke1.nsg_ids
}

# Network Peering Outputs
output "peering_hub_to_spoke1_id" {
  description = "ID of the hub to spoke1 peering"
  value       = azurerm_virtual_network_peering.hub_to_spoke1.id
}

output "peering_spoke1_to_hub_id" {
  description = "ID of the spoke1 to hub peering"
  value       = azurerm_virtual_network_peering.spoke1_to_hub.id
}

# Network Configuration Summary
output "network_summary" {
  description = "Summary of the network configuration"
  value = {
    hub = {
      location     = local.network_config.hub.location
      vnet_cidr    = local.network_config.hub.vnet_cidr
      subnet_count = length(local.network_config.hub.subnets)
    }
    spoke1 = {
      location     = local.network_config.spoke1.location
      vnet_cidr    = local.network_config.spoke1.vnet_cidr
      subnet_count = length(local.network_config.spoke1.subnets)
    }
    peering_status = "configured"
  }
}
