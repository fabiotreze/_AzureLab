# General Configuration
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "azurelab"

  validation {
    condition     = length(var.resource_prefix) <= 10 && can(regex("^[a-z0-9]+$", var.resource_prefix))
    error_message = "Resource prefix must be 10 characters or less and contain only lowercase letters and numbers."
  }
}

# Hub Network Configuration
variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "hub_subnets" {
  description = "Hub network subnets configuration"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = {
    "GatewaySubnet" = {
      address_prefixes = ["10.0.1.0/27"]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.2.0/26"]
    }
    "AzureBastionSubnet" = {
      address_prefixes = ["10.0.3.0/27"]
    }
    "hub-internal" = {
      address_prefixes  = ["10.0.10.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }
}

# Spoke Network Configuration
variable "spoke_vnets" {
  description = "Spoke virtual networks configuration"
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes  = list(string)
      service_endpoints = optional(list(string), [])
    }))
  }))
  default = {
    "spoke1" = {
      address_space = ["10.1.0.0/16"]
      subnets = {
        "web" = {
          address_prefixes  = ["10.1.1.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
        "app" = {
          address_prefixes  = ["10.1.2.0/24"]
          service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
        }
      }
    }
    "spoke2" = {
      address_space = ["10.2.0.0/16"]
      subnets = {
        "data" = {
          address_prefixes  = ["10.2.1.0/24"]
          service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
        }
        "compute" = {
          address_prefixes = ["10.2.2.0/24"]
        }
      }
    }
  }
}

# Security Configuration
variable "enable_azure_firewall" {
  description = "Enable Azure Firewall in the hub"
  type        = bool
  default     = true
}

variable "enable_azure_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard"
  type        = bool
  default     = false
}

variable "allowed_source_ips" {
  description = "List of source IP addresses allowed for management access"
  type        = list(string)
  default     = []
}

# Monitoring and Logging
variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}