# AzureLab - Terraform Hub-Spoke Network Architecture

AzureLab Scripts – Terraform configuration to deploy a secure, modular Azure Hub-Spoke network for labs and testing.

**⚠️ Disclaimer:** This repository is based on personal learning and experimentation. Use at your own risk; please review carefully before applying.

## Architecture Overview

This Terraform configuration deploys a secure, scalable Hub-Spoke network architecture in Microsoft Azure, following best practices for network segmentation, security, and monitoring.

### Components Deployed

#### Hub Network
- **Hub Virtual Network** - Central network with shared services
- **Azure Firewall** - Network security and traffic filtering
- **Azure Bastion** - Secure RDP/SSH access to VMs
- **Gateway Subnet** - For VPN/ExpressRoute connectivity
- **Shared Services** - Log Analytics, Storage Account for diagnostics

#### Spoke Networks
- **Spoke Virtual Networks** - Workload-specific networks
- **Application Subnets** - Web, App, Data, Compute tiers
- **Network Security Groups** - Subnet-level security rules
- **Route Tables** - Traffic routing through the firewall

#### Security Features
- Network segmentation with NSGs
- Centralized traffic filtering via Azure Firewall
- Secure bastion access for management
- VNet peering with controlled connectivity
- Comprehensive logging and monitoring

### Network Topology

```
                    ┌─────────────────┐
                    │   Hub Network   │
                    │   10.0.0.0/16   │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │   Firewall  │ │
                    │ │             │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │   Bastion   │ │
                    │ └─────────────┘ │
                    └─────────────────┘
                           │    │
              ┌────────────┘    └────────────┐
              │                              │
    ┌─────────────────┐              ┌─────────────────┐
    │  Spoke1 Network │              │  Spoke2 Network │
    │  10.1.0.0/16    │              │  10.2.0.0/16    │
    │                 │              │                 │
    │ ┌─────┐ ┌─────┐ │              │ ┌─────┐ ┌─────┐ │
    │ │ Web │ │ App │ │              │ │Data │ │Comp │ │
    │ └─────┘ └─────┘ │              │ └─────┘ └─────┘ │
    └─────────────────┘              └─────────────────┘
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- Azure subscription with appropriate permissions
- Basic understanding of Azure networking concepts

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/fabiotreze/_AzureLab.git
   cd _AzureLab
   ```

2. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific configuration
   ```

4. **Initialize and deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev, test, prod) | `"lab"` | No |
| `location` | Azure region for deployment | `"East US"` | No |
| `resource_prefix` | Prefix for resource naming | `"azurelab"` | No |
| `hub_vnet_address_space` | Hub network CIDR blocks | `["10.0.0.0/16"]` | No |
| `spoke_vnets` | Spoke network configuration | See example | No |
| `enable_azure_firewall` | Deploy Azure Firewall | `true` | No |
| `enable_azure_bastion` | Deploy Azure Bastion | `true` | No |
| `enable_monitoring` | Enable logging and monitoring | `true` | No |

### Customization Examples

#### Adding a New Spoke Network

```hcl
spoke_vnets = {
  "spoke1" = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      "web" = {
        address_prefixes = ["10.1.1.0/24"]
        service_endpoints = ["Microsoft.Storage"]
      }
    }
  }
  # Add your new spoke
  "spoke3" = {
    address_space = ["10.3.0.0/16"]
    subnets = {
      "database" = {
        address_prefixes = ["10.3.1.0/24"]
        service_endpoints = ["Microsoft.Sql"]
      }
    }
  }
}
```

#### Modifying Security Rules

The configuration includes default NSG rules. For custom rules, modify the `azurerm_network_security_group` resources in `main.tf`.

## Security Considerations

### Default Security Posture
- **Deny by default** - All inbound traffic is denied unless explicitly allowed
- **VNet isolation** - Inter-VNet communication only through the hub
- **Firewall filtering** - All internet traffic routed through Azure Firewall
- **Bastion access** - No direct RDP/SSH exposure to the internet

### Recommended Practices
1. **Regular updates** - Keep Terraform and providers up to date
2. **Least privilege** - Grant minimum required permissions
3. **Network monitoring** - Enable NSG flow logs and traffic analytics
4. **Regular audits** - Review security rules and access patterns

## Cost Optimization

### Resource Costs (Approximate)
- **Azure Firewall**: ~$1.25/hour + data processing
- **Azure Bastion**: ~$0.19/hour (Basic)
- **VNet Peering**: Data transfer charges
- **Log Analytics**: Pay-per-GB ingested

### Cost Reduction Options
```hcl
# Disable expensive components for testing
enable_azure_firewall = false  # Saves ~$900/month
enable_azure_bastion = false   # Saves ~$140/month
enable_monitoring = false      # Reduces logging costs
```

## Outputs

After deployment, Terraform provides:
- Resource group names and IDs
- Virtual network names and IDs
- Subnet information
- Firewall private IP address
- Bastion FQDN
- Monitoring workspace details

## Maintenance

### Regular Tasks
- **Security updates** - Review and update NSG rules
- **Cost review** - Monitor resource usage and costs
- **Backup validation** - Ensure configurations are backed up

### Scaling
- Add spoke networks by updating `spoke_vnets` variable
- Modify subnet sizes by updating address prefixes
- Add additional security rules as needed

## Troubleshooting

### Common Issues

1. **Firewall deployment fails**
   - Ensure AzureFirewallSubnet is /26 or larger
   - Check Azure Firewall availability in your region

2. **Bastion deployment fails**
   - Ensure AzureBastionSubnet is exactly /27
   - Verify public IP is Standard SKU

3. **Peering issues**
   - Check for overlapping address spaces
   - Verify resource group permissions

### Terraform State Management

For production use, consider:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstateaccount"
    container_name       = "terraform-state"
    key                  = "azurelab.terraform.tfstate"
  }
}
```

## Contributing

This is a personal learning repository. Feel free to:
- Report issues
- Suggest improvements
- Share your modifications

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Resources

- [Azure Hub-Spoke Documentation](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
