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

variable "resource_group_locations" {
  description = "Configuration for resource group locations"
  type = map(string)

  default = {
    hub    = "southcentralus"  # SCU for South Central US
    spoke1 = "brazilsouth"     # BRS for Brazil South
  }

  validation {
    condition = alltrue([
      for location in values(var.resource_group_locations) :
      contains([
        "brazilsouth", "brazilsoutheast", "eastus", "eastus2",
        "westus", "westus2", "centralus", "northcentralus", "southcentralus"
      ], location)
    ])
    error_message = "All locations must be valid Azure regions."
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