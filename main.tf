# Hub-Spoke Network Infrastructure
# This configuration creates a hub-spoke network topology in Azure
# with optimized security, naming conventions, and network design

# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_group_config

  name     = each.value.name
  location = each.value.location

  tags = merge(local.common_tags, {
    ResourceType = "ResourceGroup"
    NetworkRole  = each.key
  })
}

# Hub VNet
module "vnet_hub" {
  source = "./modules/vnet"

  vnet_name           = "${local.naming_convention.vnet}-hub-${local.region_abbreviation[local.network_config.hub.location]}"
  location            = local.network_config.hub.location
  resource_group_name = azurerm_resource_group.rg["hub"].name
  vnet_cidr           = local.network_config.hub.vnet_cidr
  subnets = {
    for subnet_name, subnet_cidr in local.network_config.hub.subnets :
    "${subnet_name}" => {
      cidr = subnet_cidr
      # Hub subnets (gateway/firewall) don't need custom security rules
      security_rules = {}
    }
  }

  tags = merge(local.common_tags, {
    NetworkRole = "Hub"
    NetworkTier = "Core"
  })

  depends_on = [azurerm_resource_group.rg]
}

# Spoke1 VNet
module "vnet_spoke1" {
  source = "./modules/vnet"

  vnet_name           = "${local.naming_convention.vnet}-spoke1-${local.region_abbreviation[local.network_config.spoke1.location]}"
  location            = local.network_config.spoke1.location
  resource_group_name = azurerm_resource_group.rg["spoke1"].name
  vnet_cidr           = local.network_config.spoke1.vnet_cidr
  subnets = {
    for subnet_name, subnet_cidr in local.network_config.spoke1.subnets :
    "${subnet_name}" => {
      cidr = subnet_cidr
      security_rules = subnet_name == "app" ? {
        "allow-http" = {
          name                       = "Allow-HTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "10.0.0.0/16"
          destination_address_prefix = "*"
        }
        "allow-https" = {
          name                       = "Allow-HTTPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "10.0.0.0/16"
          destination_address_prefix = "*"
        }
        } : subnet_name == "mgmt" ? {
        "allow-ssh" = {
          name                       = "Allow-SSH"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "10.0.0.0/16"
          destination_address_prefix = "*"
        }
        "allow-rdp" = {
          name                       = "Allow-RDP"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "3389"
          source_address_prefix      = "10.0.0.0/16"
          destination_address_prefix = "*"
        }
        } : subnet_name == "adds" ? {
        "allow-ldap" = {
          name                       = "Allow-LDAP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "389"
          source_address_prefix      = "172.16.0.0/16"
          destination_address_prefix = "*"
        }
        "allow-ldaps" = {
          name                       = "Allow-LDAPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "636"
          source_address_prefix      = "172.16.0.0/16"
          destination_address_prefix = "*"
        }
        "allow-kerberos" = {
          name                       = "Allow-Kerberos"
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "88"
          source_address_prefix      = "172.16.0.0/16"
          destination_address_prefix = "*"
        }
      } : {}
    }
  }

  tags = merge(local.common_tags, {
    NetworkRole = "Spoke"
    NetworkTier = "Application"
  })

  depends_on = [azurerm_resource_group.rg]
}

# VNet Peering: Hub to Spoke1
# Note: Gateway settings are disabled until VPN Gateway is actually deployed
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "${local.naming_convention.peering}-hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.rg["hub"].name
  virtual_network_name      = module.vnet_hub.vnet_name
  remote_virtual_network_id = module.vnet_spoke1.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false # Set to true after VPN Gateway deployment
  use_remote_gateways          = false

  depends_on = [
    module.vnet_hub,
    module.vnet_spoke1
  ]
}

# VNet Peering: Spoke1 to Hub
# Note: use_remote_gateways will be enabled after VPN Gateway is deployed in hub
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "${local.naming_convention.peering}-spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.rg["spoke1"].name
  virtual_network_name      = module.vnet_spoke1.vnet_name
  remote_virtual_network_id = module.vnet_hub.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false # Set to true after VPN Gateway deployment

  depends_on = [
    module.vnet_hub,
    module.vnet_spoke1,
    azurerm_virtual_network_peering.hub_to_spoke1
  ]
}