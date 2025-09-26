# Variables for the generic VNet module

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "The vnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    cidr              = string
    service_endpoints = optional(list(string), [])
    security_rules = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : can(cidrhost(subnet.cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}