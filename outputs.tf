# Standardized Outputs for Hub-Spoke Network Infrastructure
# Format: name, id, location, resource_group_name + relevant resource-specific information

# ==========================================
# RESOURCE GROUPS
# ==========================================
output "resource_groups" {
  description = "All resource groups with standardized information"
  value = {
    for k, rg in azurerm_resource_group.rg : k => {
      name     = rg.name
      id       = rg.id
      location = rg.location
      tags     = rg.tags
    }
  }
}

# ==========================================
# VIRTUAL NETWORKS
# ==========================================
output "virtual_networks" {
  description = "All virtual networks with standardized information"
  value = {
    hub = {
      name                = module.vnet_hub.vnet.name
      id                  = module.vnet_hub.vnet.id
      location            = module.vnet_hub.vnet.location
      resource_group_name = module.vnet_hub.vnet.resource_group_name
      address_space       = module.vnet_hub.vnet.address_space
      dns_servers         = module.vnet_hub.vnet.dns_servers
      role                = "hub"
    }
    spoke1 = {
      name                = module.vnet_spoke1.vnet.name
      id                  = module.vnet_spoke1.vnet.id
      location            = module.vnet_spoke1.vnet.location
      resource_group_name = module.vnet_spoke1.vnet.resource_group_name
      address_space       = module.vnet_spoke1.vnet.address_space
      dns_servers         = module.vnet_spoke1.vnet.dns_servers
      role                = "spoke"
    }
  }
}

# ==========================================
# SUBNETS
# ==========================================
output "subnets" {
  description = "All subnets across all VNets with standardized information"
  value = merge(
    # Hub subnets
    {
      for k, subnet in module.vnet_hub.subnets : "hub-${k}" => merge(subnet, {
        network_role = "hub"
        vnet_name    = module.vnet_hub.vnet.name
      })
    },
    # Spoke1 subnets  
    {
      for k, subnet in module.vnet_spoke1.subnets : "spoke1-${k}" => merge(subnet, {
        network_role = "spoke"
        vnet_name    = module.vnet_spoke1.vnet.name
      })
    }
  )
}

# ==========================================
# NETWORK SECURITY GROUPS
# ==========================================
output "network_security_groups" {
  description = "All NSGs across all VNets with standardized information"
  value = merge(
    # Hub NSGs
    {
      for k, nsg in module.vnet_hub.nsgs : "hub-${k}" => merge(nsg, {
        network_role = "hub"
        vnet_name    = module.vnet_hub.vnet.name
      })
    },
    # Spoke1 NSGs
    {
      for k, nsg in module.vnet_spoke1.nsgs : "spoke1-${k}" => merge(nsg, {
        network_role = "spoke"
        vnet_name    = module.vnet_spoke1.vnet.name
      })
    }
  )
}

# ==========================================
# DNS ZONES (Private DNS)
# ==========================================
output "dns_zones" {
  description = "All private DNS zones with standardized information"
  value = {
    for k, zone in module.dns_hub.dns_zones : k => merge(zone, {
      network_role = "hub"
      zone_type    = "private"
    })
  }
}

# ==========================================
# VNet PEERINGS  
# ==========================================
output "vnet_peerings" {
  description = "All VNet peerings with standardized information"
  value = {
    hub-to-spoke1 = {
      name                = azurerm_virtual_network_peering.hub_to_spoke1.name
      id                  = azurerm_virtual_network_peering.hub_to_spoke1.id
      location            = module.vnet_hub.vnet.location
      resource_group_name = azurerm_virtual_network_peering.hub_to_spoke1.resource_group_name
      virtual_network_name = azurerm_virtual_network_peering.hub_to_spoke1.virtual_network_name
      remote_virtual_network_id = azurerm_virtual_network_peering.hub_to_spoke1.remote_virtual_network_id
      peering_direction   = "hub-to-spoke"
      allow_forwarded_traffic = azurerm_virtual_network_peering.hub_to_spoke1.allow_forwarded_traffic
      use_remote_gateways = azurerm_virtual_network_peering.hub_to_spoke1.use_remote_gateways
    }
    spoke1-to-hub = {
      name                = azurerm_virtual_network_peering.spoke1_to_hub.name
      id                  = azurerm_virtual_network_peering.spoke1_to_hub.id
      location            = module.vnet_spoke1.vnet.location
      resource_group_name = azurerm_virtual_network_peering.spoke1_to_hub.resource_group_name
      virtual_network_name = azurerm_virtual_network_peering.spoke1_to_hub.virtual_network_name
      remote_virtual_network_id = azurerm_virtual_network_peering.spoke1_to_hub.remote_virtual_network_id
      peering_direction   = "spoke-to-hub"
      allow_forwarded_traffic = azurerm_virtual_network_peering.spoke1_to_hub.allow_forwarded_traffic
      use_remote_gateways = azurerm_virtual_network_peering.spoke1_to_hub.use_remote_gateways
    }
  }
}

# ==========================================
# INFRASTRUCTURE SUMMARY
# ==========================================
output "infrastructure_summary" {
  description = "High-level summary of the deployed infrastructure"
  value = {
    environment         = local.environment
    project            = local.project
    resource_groups    = length(azurerm_resource_group.rg)
    virtual_networks   = 2
    subnets_total      = length(local.network_config.hub.subnets) + length(local.network_config.spoke1.subnets)
    dns_zones          = length(module.dns_hub.dns_zones)
    vnet_peerings      = 2
    regions_used       = distinct([local.network_config.hub.location, local.network_config.spoke1.location])
    deployment_date    = local.common_tags.CreatedDate
  }
}
