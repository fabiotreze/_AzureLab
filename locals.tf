# Local values for resource naming and configuration standardization
locals {
  # Region abbreviations for consistent naming
  region_abbreviation = {
    "brazilsouth"    = "brs"
    "southcentralus" = "scu"
    "eastus2"        = "eus2"
  }

  # Environment configuration
  environment = var.environment
  project     = "hub-spoke-network"

  # Common tags applied to all resources
  common_tags = {
    Environment = local.environment
    Project     = local.project
    Owner       = "infrastructure-team"
    CreatedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    CostCenter  = "IT-Infrastructure"
  }

  # Standardized naming convention
  naming_convention = {
    resource_group = "rg-${local.project}-${local.environment}"
    vnet           = "vnet-${local.project}-${local.environment}"
    subnet         = "snet-${local.project}-${local.environment}"
    nsg            = "nsg-${local.project}-${local.environment}"
    peering        = "peer-${local.project}-${local.environment}"
    dns            = "pdns-${local.project}-${local.environment}"
  }

  # Dynamic resource group configuration using naming convention and locations
  resource_group_config = {
    for network_key, network_config in local.network_config :
    network_key => {
      name     = "${local.naming_convention.resource_group}-${network_key}-${local.region_abbreviation[network_config.location]}"
      location = network_config.location
    }
  }

  # Network configuration with updated CIDR blocks and dynamic regions
  network_config = {
    hub = {
      name      = "hub"
      location  = var.resource_group_locations.hub # Dynamic location from variable
      vnet_cidr = "10.0.0.0/16"                    # /16 network for hub
      subnets = {
        "gateway"  = "10.0.0.0/27"  # 30 IPs for VPN Gateway
        "firewall" = "10.0.0.32/27" # 30 IPs for Azure Firewall
      }
    }
    spoke1 = {
      name      = "spoke1"
      location  = var.resource_group_locations.spoke1 # Dynamic location from variable
      vnet_cidr = "172.16.0.0/16"                     # /16 network for spoke
      subnets = {
        "app"     = "172.16.1.0/24" # 254 IPs for applications
        "mgmt"    = "172.16.2.0/24" # 254 IPs for management/jump box
        "adds"    = "172.16.3.0/24" # 254 IPs for Active Directory DS
        "peering" = "172.16.4.0/24" # 254 IPs for hub communication
      }
    }
  }

  # NSG rules configuration for new subnet structure
  nsg_rules = {
    app_tier = [
      {
        name                       = "Allow-HTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "10.0.0.0/16" # Only from hub network
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "10.0.0.0/16" # Only from hub network
        destination_address_prefix = "*"
      }
    ]
    management = [
      {
        name                       = "Allow-SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.0.0.0/16" # Only from hub network
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-RDP"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "10.0.0.0/16" # Only from hub network
        destination_address_prefix = "*"
      }
    ]
    adds = [
      {
        name                       = "Allow-LDAP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "389"
        source_address_prefix      = "172.16.0.0/16" # Only from spoke network
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-LDAPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "636"
        source_address_prefix      = "172.16.0.0/16" # Only from spoke network
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-Kerberos"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "88"
        source_address_prefix      = "172.16.0.0/16" # Only from spoke network
        destination_address_prefix = "*"
      }
    ]
  }
}