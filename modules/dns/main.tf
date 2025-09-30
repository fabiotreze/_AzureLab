
# Private DNS Zones - Generic module for Azure private link zones
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each = var.dns_zones

  name                = each.value.zone_name
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Purpose = "Private DNS Zone"
    Zone    = each.key
  })
}

# Virtual Network Links for DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "dns_links" {
  for_each = var.dns_zones

  name                  = "${var.name}-${each.key}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones[each.key].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = each.value.registration_enabled

  tags = merge(var.tags, {
    Purpose = "DNS VNet Link"
    Zone    = each.key
  })
}
