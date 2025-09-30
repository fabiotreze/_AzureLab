# Generic VNet module for hub-spoke architecture

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = merge(var.tags, {
    Name = var.vnet_name
    Type = "VirtualNetwork"
  })
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.cidr]

  # Optional service endpoints
  service_endpoints = lookup(each.value, "service_endpoints", [])

  # Optional subnet delegation
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  depends_on = [azurerm_virtual_network.vnet]
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Name   = "nsg-${each.key}-${var.vnet_name}"
    Type   = "NetworkSecurityGroup"
    Subnet = each.key
  })

  depends_on = [azurerm_virtual_network.vnet]
}

# Security Rules
resource "azurerm_network_security_rule" "security_rules" {
  for_each = local.flattened_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_name].name

  depends_on = [azurerm_network_security_group.nsg]
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id

  depends_on = [
    azurerm_subnet.subnets,
    azurerm_network_security_group.nsg
  ]
}

# Local values for flattening security rules
locals {
  flattened_rules = {
    for rule_key, rule in flatten([
      for subnet_name, subnet_config in var.subnets : [
        for rule_name, rule_config in lookup(subnet_config, "security_rules", {}) : {
          key                        = "${subnet_name}-${rule_name}"
          subnet_name                = subnet_name
          name                       = rule_config.name
          priority                   = rule_config.priority
          direction                  = rule_config.direction
          access                     = rule_config.access
          protocol                   = rule_config.protocol
          source_port_range          = rule_config.source_port_range
          destination_port_range     = rule_config.destination_port_range
          source_address_prefix      = rule_config.source_address_prefix
          destination_address_prefix = rule_config.destination_address_prefix
        }
      ]
    ]) : rule.key => rule
  }
}
