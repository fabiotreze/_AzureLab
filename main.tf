# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Local values for common configurations
locals {
  common_tags = merge({
    Environment = var.environment
    Project     = "AzureLab"
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }, var.additional_tags)

  # Flatten spoke subnets for easier iteration
  spoke_subnets_flat = {
    for spoke_name, spoke_config in var.spoke_vnets : spoke_name => spoke_config.subnets
  }
}

# Resource Groups
resource "azurerm_resource_group" "hub" {
  name     = "${var.resource_prefix}-hub-${var.environment}-${random_string.suffix.result}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "spoke" {
  for_each = var.spoke_vnets

  name     = "${var.resource_prefix}-${each.key}-${var.environment}-${random_string.suffix.result}-rg"
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace (if monitoring enabled)
resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${var.resource_prefix}-logs-${var.environment}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# Storage Account for Diagnostics
resource "azurerm_storage_account" "diagnostics" {
  count = var.enable_monitoring ? 1 : 0

  name                     = "${var.resource_prefix}diag${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = var.log_retention_days
    }
  }

  tags = local.common_tags
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "${var.resource_prefix}-hub-${var.environment}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub_vnet_address_space
  tags                = local.common_tags
}

# Hub Subnets
resource "azurerm_subnet" "hub" {
  for_each = var.hub_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# Spoke Virtual Networks
resource "azurerm_virtual_network" "spoke" {
  for_each = var.spoke_vnets

  name                = "${var.resource_prefix}-${each.key}-${var.environment}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  address_space       = each.value.address_space
  tags                = local.common_tags
}

# Spoke Subnets
resource "azurerm_subnet" "spoke" {
  for_each = {
    for combination in flatten([
      for spoke_name, spoke_config in var.spoke_vnets : [
        for subnet_name, subnet_config in spoke_config.subnets : {
          key               = "${spoke_name}-${subnet_name}"
          spoke_name        = spoke_name
          subnet_name       = subnet_name
          address_prefixes  = subnet_config.address_prefixes
          service_endpoints = subnet_config.service_endpoints
        }
      ]
    ]) : combination.key => combination
  }

  name                 = each.value.subnet_name
  resource_group_name  = azurerm_resource_group.spoke[each.value.spoke_name].name
  virtual_network_name = azurerm_virtual_network.spoke[each.value.spoke_name].name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                         = "hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                         = "${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.spoke[each.key].name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "${var.resource_prefix}-fw-${var.environment}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = "${var.resource_prefix}-fw-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  tags = local.common_tags
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count = var.enable_azure_bastion ? 1 : 0

  name                = "${var.resource_prefix}-bastion-${var.environment}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Bastion
resource "azurerm_bastion_host" "main" {
  count = var.enable_azure_bastion ? 1 : 0

  name                = "${var.resource_prefix}-bastion-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.common_tags
}

# Route Tables for Spoke Networks (to route through firewall)
resource "azurerm_route_table" "spoke" {
  for_each = var.enable_azure_firewall ? var.spoke_vnets : {}

  name                = "${var.resource_prefix}-${each.key}-${var.environment}-rt"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  tags                = local.common_tags

  route {
    name                   = "DefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.main[0].ip_configuration[0].private_ip_address
  }
}

# Associate Route Tables with Spoke Subnets
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.enable_azure_firewall ? {
    for combination in flatten([
      for spoke_name, spoke_config in var.spoke_vnets : [
        for subnet_name, subnet_config in spoke_config.subnets : {
          key        = "${spoke_name}-${subnet_name}"
          spoke_name = spoke_name
          subnet_id  = azurerm_subnet.spoke["${spoke_name}-${subnet_name}"].id
        }
      ]
    ]) : combination.key => combination
  } : {}

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.spoke[each.value.spoke_name].id
}

# Network Security Groups for Hub Subnets
resource "azurerm_network_security_group" "hub" {
  for_each = {
    for subnet_name, subnet_config in var.hub_subnets : subnet_name => subnet_config
    if !contains(["GatewaySubnet", "AzureFirewallSubnet", "AzureBastionSubnet"], subnet_name)
  }

  name                = "${var.resource_prefix}-hub-${each.key}-${var.environment}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags

  # Default deny all inbound rule
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow internal VNet communication
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

# Network Security Groups for Spoke Subnets
resource "azurerm_network_security_group" "spoke" {
  for_each = {
    for combination in flatten([
      for spoke_name, spoke_config in var.spoke_vnets : [
        for subnet_name, subnet_config in spoke_config.subnets : {
          key         = "${spoke_name}-${subnet_name}"
          spoke_name  = spoke_name
          subnet_name = subnet_name
        }
      ]
    ]) : combination.key => combination
  }

  name                = "${var.resource_prefix}-${each.value.spoke_name}-${each.value.subnet_name}-${var.environment}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke[each.value.spoke_name].name
  tags                = local.common_tags

  # Default deny all inbound rule
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow internal VNet communication
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow HTTP/HTTPS for web subnets
  dynamic "security_rule" {
    for_each = each.value.subnet_name == "web" ? [1] : []
    content {
      name                       = "AllowHTTPInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}

# Associate NSGs with Hub Subnets
resource "azurerm_subnet_network_security_group_association" "hub" {
  for_each = {
    for subnet_name, subnet_config in var.hub_subnets : subnet_name => subnet_config
    if !contains(["GatewaySubnet", "AzureFirewallSubnet", "AzureBastionSubnet"], subnet_name)
  }

  subnet_id                 = azurerm_subnet.hub[each.key].id
  network_security_group_id = azurerm_network_security_group.hub[each.key].id
}

# Associate NSGs with Spoke Subnets
resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = {
    for combination in flatten([
      for spoke_name, spoke_config in var.spoke_vnets : [
        for subnet_name, subnet_config in spoke_config.subnets : {
          key       = "${spoke_name}-${subnet_name}"
          subnet_id = azurerm_subnet.spoke["${spoke_name}-${subnet_name}"].id
        }
      ]
    ]) : combination.key => combination
  }

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}