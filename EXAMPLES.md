# Azure Hub-Spoke Lab Deployment Examples

This directory contains example configurations and deployment scenarios for the AzureLab Hub-Spoke architecture.

## Quick Start Examples

### Minimal Configuration (Cost-Optimized)
```hcl
# terraform.tfvars
environment     = "dev"
location        = "East US"
resource_prefix = "mylab"

# Disable expensive components for testing
enable_azure_firewall = false
enable_azure_bastion  = false
enable_monitoring     = false

# Simple spoke configuration
spoke_vnets = {
  "spoke1" = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      "app" = {
        address_prefixes = ["10.1.1.0/24"]
      }
    }
  }
}
```

### Production Configuration
```hcl
# terraform.tfvars
environment     = "prod"
location        = "East US"
resource_prefix = "company"

# Full security stack
enable_azure_firewall   = true
enable_azure_bastion    = true
enable_ddos_protection  = true
enable_monitoring       = true

# Multiple spokes for different workloads
spoke_vnets = {
  "web-tier" = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      "frontend" = {
        address_prefixes  = ["10.1.1.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
      "backend" = {
        address_prefixes  = ["10.1.2.0/24"]
        service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      }
    }
  }
  "data-tier" = {
    address_space = ["10.2.0.0/16"]
    subnets = {
      "database" = {
        address_prefixes  = ["10.2.1.0/24"]
        service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      }
      "analytics" = {
        address_prefixes = ["10.2.2.0/24"]
      }
    }
  }
}

additional_tags = {
  Owner       = "IT Team"
  Environment = "production"
  CostCenter  = "12345"
}
```

## Deployment Commands

### Standard Deployment
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit variables as needed
nano terraform.tfvars

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### Targeted Deployment
```bash
# Deploy only network components
terraform apply -target=azurerm_virtual_network.hub -target=azurerm_virtual_network.spoke

# Deploy only security components
terraform apply -target=azurerm_network_security_group.hub -target=azurerm_network_security_group.spoke
```

### Environment-Specific Deployments
```bash
# Development environment
terraform apply -var-file="environments/dev.tfvars"

# Production environment
terraform apply -var-file="environments/prod.tfvars"
```

## Common Customizations

### Adding Application Gateway
To add Azure Application Gateway for web applications:

1. Add to variables.tf:
```hcl
variable "enable_application_gateway" {
  description = "Enable Application Gateway for web traffic"
  type        = bool
  default     = false
}
```

2. Add subnet to hub_subnets:
```hcl
"ApplicationGatewaySubnet" = {
  address_prefixes = ["10.0.4.0/24"]
}
```

### Custom NSG Rules
Add custom security rules to allow specific traffic:

```hcl
# In main.tf, add to network security group
security_rule {
  name                       = "AllowHTTPS"
  priority                   = 1000
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"
}
```

## Cleanup

### Complete Cleanup
```bash
terraform destroy
```

### Selective Cleanup
```bash
# Remove expensive components only
terraform destroy -target=azurerm_firewall.main -target=azurerm_bastion_host.main
```

## Troubleshooting

See the main [README.md](../README.md#troubleshooting) for common issues and solutions.