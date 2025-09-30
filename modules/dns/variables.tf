# Variables for the generic DNS module

variable "name" {
  description = "Base name for DNS resources"
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

variable "virtual_network_id" {
  description = "ID of the Virtual Network where DNS links should be associated"
  type        = string
}

variable "dns_zones" {
  description = "Map of DNS zones to create"
  type = map(object({
    zone_name            = string
    registration_enabled = bool
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
