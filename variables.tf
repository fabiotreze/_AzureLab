# Variables for hub-spoke network infrastructure

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "primary_location" {
  description = "Primary Azure region for resources"
  type        = string
  default     = "southcentralus" # Changed to South Central US for hub

  validation {
    condition = contains([
      "brazilsouth", "brazilsoutheast", "eastus", "eastus2",
      "westus", "westus2", "centralus", "northcentralus", "southcentralus"
    ], var.primary_location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "resource_group_config" {
  description = "Configuration for resource groups"
  type = map(object({
    name     = string
    location = string
  }))

  default = {
    hub = {
      name     = "rg-hub-spoke-network-dev-scu" # SCU for South Central US
      location = "southcentralus"
    }
    spoke1 = {
      name     = "rg-spoke1-network-dev-brs" # BRS for Brazil South
      location = "brazilsouth"
    }
  }

  validation {
    condition = alltrue([
      for rg in values(var.resource_group_config) :
      can(regex("^rg-", rg.name))
    ])
    error_message = "All resource group names must start with 'rg-'."
  }
}

variable "enable_network_watcher" {
  description = "Enable Network Watcher for monitoring"
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard"
  type        = bool
  default     = false # Set to true for production workloads
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring"
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
