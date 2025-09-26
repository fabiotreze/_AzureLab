# Resource Group Outputs
output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "spoke_resource_group_names" {
  description = "Names of the spoke resource groups"
  value       = { for k, v in azurerm_resource_group.spoke : k => v.name }
}

# Network Outputs
output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_ids" {
  description = "IDs of the spoke virtual networks"
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "spoke_vnet_names" {
  description = "Names of the spoke virtual networks"
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.name }
}

# Subnet Outputs
output "hub_subnet_ids" {
  description = "IDs of hub subnets"
  value       = { for k, v in azurerm_subnet.hub : k => v.id }
}

output "spoke_subnet_ids" {
  description = "IDs of spoke subnets"
  value = {
    for spoke_name, spoke_subnets in local.spoke_subnets_flat :
    spoke_name => { for subnet_key, subnet in spoke_subnets : subnet_key => azurerm_subnet.spoke["${spoke_name}-${subnet_key}"].id }
  }
}

# Security Outputs
output "azure_firewall_private_ip" {
  description = "Private IP address of Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "azure_bastion_fqdn" {
  description = "FQDN of Azure Bastion"
  value       = var.enable_azure_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].name : null
}

# Storage Outputs
output "diagnostics_storage_account_name" {
  description = "Name of the diagnostics storage account"
  value       = var.enable_monitoring ? azurerm_storage_account.diagnostics[0].name : null
}

# Network Security Group Outputs
output "hub_nsg_ids" {
  description = "IDs of hub network security groups"
  value       = { for k, v in azurerm_network_security_group.hub : k => v.id }
}

output "spoke_nsg_ids" {
  description = "IDs of spoke network security groups"
  value = {
    for spoke_name, spoke_subnets in local.spoke_subnets_flat :
    spoke_name => { for subnet_key, subnet in spoke_subnets : subnet_key => azurerm_network_security_group.spoke["${spoke_name}-${subnet_key}"].id }
  }
}