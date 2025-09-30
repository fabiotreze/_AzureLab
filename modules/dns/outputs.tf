# DNS Module Outputs - Standardized format

# DNS Zones
output "dns_zones" {
  description = "Map of DNS zones with standardized information"
  value = {
    for k, zone in azurerm_private_dns_zone.dns_zones : k => {
      name                = zone.name
      id                  = zone.id
      location            = "Global" # Private DNS zones are global
      resource_group_name = zone.resource_group_name
      fqdn                = zone.name
    }
  }
}

# DNS Zone IDs (for reference)
output "dns_zone_ids" {
  description = "Map of DNS zone names to their IDs"
  value       = { for k, zone in azurerm_private_dns_zone.dns_zones : k => zone.id }
}

# DNS Zone Names (for reference) 
output "dns_zone_names" {
  description = "Map of DNS zone keys to their full names"
  value       = { for k, zone in azurerm_private_dns_zone.dns_zones : k => zone.name }
}

# VNet Links
output "dns_links" {
  description = "Map of DNS VNet links with standardized information"
  value = {
    for k, link in azurerm_private_dns_zone_virtual_network_link.dns_links : k => {
      name                  = link.name
      id                    = link.id
      location              = "Global" # DNS links are global
      resource_group_name   = link.resource_group_name
      private_dns_zone_name = link.private_dns_zone_name
      virtual_network_id    = link.virtual_network_id
      registration_enabled  = link.registration_enabled
    }
  }
}