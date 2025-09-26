# Hub-Spoke Network Infrastructure

This Terraform configuration creates a hub-spoke network topology in Azure with optimized security, naming conventions, and network design.

## 🏗️ Architecture Overview

```
┌─────────────────────────┐       ┌─────────────────────────┐
│      Hub VNet           │◄─────►│     Spoke1 VNet         │
│   10.0.0.0/16           │       │   172.16.0.0/16         │
│   South Central US      │       │   Brazil South          │
│                         │       │                         │
│ ┌─────────────────────┐ │       │ ┌─────────────────────┐ │
│ │ Gateway Subnet      │ │       │ │ Application Subnet  │ │
│ │ snet-gateway        │ │       │ │ snet-app            │ │
│ │ 10.0.0.0/27         │ │       │ │ 172.16.1.0/24       │ │
│ └─────────────────────┘ │       │ └─────────────────────┘ │
│ ┌─────────────────────┐ │       │ ┌─────────────────────┐ │
│ │ Firewall Subnet     │ │       │ │ Management Subnet   │ │
│ │ snet-firewall       │ │       │ │ snet-mgmt           │ │
│ │ 10.0.0.32/27        │ │       │ │ 172.16.2.0/24       │ │
│ └─────────────────────┘ │       │ └─────────────────────┘ │
│                         │       │ ┌─────────────────────┐ │
│                         │       │ │ AD DS Subnet        │ │
│                         │       │ │ snet-adds           │ │
│                         │       │ │ 172.16.3.0/24       │ │
│                         │       │ └─────────────────────┘ │
│                         │       │ ┌─────────────────────┐ │
│                         │       │ │ Peering Subnet      │ │
│                         │       │ │ snet-peering        │ │
│                         │       │ │ 172.16.4.0/24       │ │
│                         │       │ └─────────────────────┘ │
└─────────────────────────┘       └─────────────────────────┘
```

## 🚀 Features

- **Hub-Spoke Topology**: Centralized connectivity and shared services
- **Multi-Region Design**: Hub in South Central US, Spoke in Brazil South
- **Optimized CIDR Allocation**: Efficient IP address usage with /16 networks
- **Network Security Groups**: Subnet-level security with custom rules
- **VNet Peering**: Secure communication between hub and spokes
- **Standardized Naming**: Consistent resource naming conventions
- **Common Tagging**: Centralized tag management
- **Modular Design**: Reusable VNet module

## 📋 Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **Service Principal** or **Managed Identity** for authentication

## 🔐 Security Setup

### Authentication Options

#### Option 1: Azure CLI (Recommended for development)
```bash
az login
az account set --subscription "your-subscription-id"
```

#### Option 2: Environment Variables
Create a `.env` file (never commit this!):
```bash
export ARM_SUBSCRIPTION_ID="YourSubscriptionID"
export ARM_CLIENT_ID="YourClientID"
export ARM_CLIENT_SECRET="YourClientSecret"
export ARM_TENANT_ID="YourTenantID"
```

Then source it:
```bash
source .env
```

## 🚀 Quick Start

1. **Clone and Navigate**
   ```bash
   cd Project1
   ```

2. **Review Configuration**
   - Check `terraform.tfvars.example` for configuration options
   - Copy to `terraform.tfvars` and customize values

3. **Initialize**
   ```bash
   terraform init
   ```

4. **Plan**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Deploy**
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## 📝 Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name | `dev` | No |
| `primary_location` | Primary Azure region | `southcentralus` | No |
| `resource_group_config` | Resource group configuration | See locals.tf | No |
| `enable_network_watcher` | Enable Network Watcher | `true` | No |
| `enable_ddos_protection` | Enable DDoS Protection | `false` | No |

### Network Configuration

The network configuration is defined in `locals.tf`:

- **Hub VNet**: `10.0.0.0/16` (65,534 usable IPs) - **South Central US (SCU)**
  - Gateway Subnet: `10.0.0.0/27` (30 IPs) - VPN Gateway
  - Firewall Subnet: `10.0.0.32/27` (30 IPs) - Azure Firewall

- **Spoke1 VNet**: `172.16.0.0/16` (65,534 usable IPs) - **Brazil South (BRS)**
  - Application Subnet: `172.16.1.0/24` (254 IPs) - Application services
  - Management Subnet: `172.16.2.0/24` (254 IPs) - Jump box/management
  - AD DS Subnet: `172.16.3.0/24` (254 IPs) - Active Directory Domain Services
  - Peering Subnet: `172.16.4.0/24` (254 IPs) - Hub communication

## 📁 Project Structure

```
Project1/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variables
├── locals.tf                  # Local values and configuration
├── outputs.tf                 # Output values
├── versions.tf                # Provider versions
├── backend.tf                 # Backend configuration
├── provider.tf                # Provider configuration
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore rules
├── README.md                  # This file
└── modules/
    └── vnet/                  # Generic VNet module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔍 Outputs

After deployment, you'll get outputs including:

- Resource Group IDs and names
- VNet IDs and names
- Subnet IDs and names
- NSG IDs and names
- Peering IDs
- Network configuration summary

## 🛡️ Security Features

### Network Security Groups (NSGs)

- **Application Tier (snet-app)**: Allows HTTP (80) and HTTPS (443) from hub network only
- **Management Tier (snet-mgmt)**: Allows SSH (22) and RDP (3389) from hub network for jump box access
- **AD DS Tier (snet-adds)**: Allows LDAP (389), LDAPS (636), and Kerberos (88) from spoke network
- **Peering Tier (snet-peering)**: No custom rules, used for hub-spoke communication
- **Hub Subnets**: Gateway and Firewall subnets use default security settings

### Network Peering

- **Hub to Spoke**: Basic peering established (gateway transit disabled until VPN Gateway deployment)
- **Spoke to Hub**: Basic peering established (remote gateway usage disabled until VPN Gateway deployment)
- **Bidirectional**: Full network connectivity for VM-to-VM communication
- **Gateway Configuration**: To enable gateway transit, deploy a VPN Gateway in the hub's gateway subnet first

> **Note**: The current configuration provides basic VNet-to-VNet connectivity. To enable centralized internet egress or on-premises connectivity, deploy Azure VPN Gateway or Azure Firewall in the hub, then update the peering settings.

## 🔄 Customization

### Adding New Spokes

To add a new spoke, modify `locals.tf`:

```hcl
spoke2 = {
  name         = "spoke2"
  location     = "brazilsouth"
  vnet_cidr    = "10.2.0.0/22"
  subnets = {
    "app"        = "10.2.0.0/24"
    "management" = "10.2.1.0/24"
  }
}
```

Then add the spoke in `main.tf` and create peering resources.

### Modifying Security Rules

Update the `nsg_rules` in `locals.tf` to add or modify security rules.

## 🏷️ Tagging Strategy

All resources are tagged with:
- **Environment**: Environment identifier
- **Project**: Project identifier
- **Owner**: Resource owner
- **CreatedBy**: Always "terraform"
- **CreatedDate**: Creation timestamp
- **CostCenter**: For cost allocation

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="terraform.tfvars"
```

## 🤝 Contributing

1. Follow the naming conventions defined in `locals.tf`
2. Add appropriate tags to new resources
3. Update documentation for any changes
4. Test with `terraform plan` before applying

## 📚 Additional Resources

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Hub-Spoke Network Topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)

## ⚠️ Important Notes

- Always review the plan before applying
- Keep your `terraform.tfvars` file secure and never commit it
- Consider using Azure Key Vault for sensitive configuration
- Monitor costs and set up alerts for unexpected charges

---

**Note**: This configuration is optimized for development and testing. For production deployments, consider additional security hardening, monitoring, and backup strategies.