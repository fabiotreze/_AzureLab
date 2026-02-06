# ⚠️ Personal Project Notice
This repository is a personal, independent project created for educational and experimental purposes.  
It is not affiliated with or endorsed by any organization, and it contains no confidential, sensitive, or proprietary information.

---

# Hub-Spoke Network Infrastructure with DNS Management

This Terraform configuration creates a comprehensive hub-spoke network topology in Azure with DNS management, security features, and standardized naming conventions.

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
                │
                ▼
    ┌─────────────────────┐
    │     DNS Zones       │
    │  Private DNS Zone   │
    │ *.internal.local    │
    │                     │
    │  Public DNS Zone    │
    │ example.com         │
    └─────────────────────┘
```

## 🚀 Features

- **Hub-Spoke Topology**: Centralized connectivity and shared services
- **Multi-Region Design**: Hub in South Central US, Spoke in Brazil South
- **DNS Management**: Private and Public DNS zones with VNet linking
- **Optimized CIDR Allocation**: Efficient IP address usage with /16 networks
- **Network Security Groups**: Subnet-level security with custom rules
- **VNet Peering**: Secure communication between hub and spokes
- **Standardized Naming**: Consistent resource naming conventions
- **Common Tagging**: Centralized tag management
- **Modular Design**: Reusable VNet and DNS modules
- **Comprehensive Outputs**: Detailed resource information for all components

## 📋 Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **Service Principal** or **Managed Identity** for authentication

## 🗄️ Backend Storage Setup

Before deploying the infrastructure, you need to create an Azure Storage Account to store Terraform state remotely. This ensures state consistency and enables team collaboration.

### Create Storage Account for Terraform State

**Option 1: Using PowerShell**
```powershell
# Based on: https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=powershell

# Define variables
$RESOURCE_GROUP_NAME='rg-tfstate-eus2'
$STORAGE_ACCOUNT_NAME="tfstate$(Get-Random)"
$CONTAINER_NAME='tfstate'

# Create resource group
New-AzResourceGroup -Name $RESOURCE_GROUP_NAME -Location eastus2 -Verbose

# Create storage account
$storageAccount = New-AzStorageAccount `
    -ResourceGroupName $RESOURCE_GROUP_NAME `
    -Name $STORAGE_ACCOUNT_NAME `
    -SkuName Standard_LRS `
    -Location eastus2 `
    -AllowBlobPublicAccess $false `
    -AllowSharedKeyAccess $true `
    -Verbose

# Create blob container
New-AzStorageContainer -Name $CONTAINER_NAME -Context $storageAccount.context -Verbose

# Get and set access key
$ACCOUNT_KEY = (Get-AzStorageAccountKey -ResourceGroupName $RESOURCE_GROUP_NAME -Name $STORAGE_ACCOUNT_NAME)[0].value
$env:ARM_ACCESS_KEY = $ACCOUNT_KEY

# Display storage account name (update backend.tf with this value)
Write-Host "Storage Account Name: $STORAGE_ACCOUNT_NAME" -ForegroundColor Green
Write-Host "Update your backend.tf with this storage account name" -ForegroundColor Yellow
```

**Option 2: Using Azure CLI**
```bash
# Define variables
RESOURCE_GROUP_NAME='rg-tfstate-eus2'
STORAGE_ACCOUNT_NAME="tfstate$RANDOM"
CONTAINER_NAME='tfstate'

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus2

# Create storage account
az storage account create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STORAGE_ACCOUNT_NAME \
    --sku Standard_LRS \
    --encryption-services blob \
    --allow-blob-public-access false

# Create blob container
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME

# Get storage account key and set environment variable
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
export ARM_ACCESS_KEY=$ACCOUNT_KEY

# Display storage account name
echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "Update your backend.tf with this storage account name"
```

### Update Backend Configuration

After creating the storage account, update `backend.tf` with your storage account name:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-eus2"
    storage_account_name = "tfstate123456789"  # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "project1-terraform.tfstate"
  }
}
```

> **Important**: The storage account name must be globally unique across all Azure accounts. The scripts above generate a random suffix to ensure uniqueness.

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

1. **Create Backend Storage** (One-time setup)
   - Follow the [Backend Storage Setup](#%EF%B8%8F-backend-storage-setup) section above
   - Update `backend.tf` with your storage account name

2. **Clone and Navigate**
   ```bash
   cd Project1
   ```

3. **Review Configuration**
   - Check `terraform.tfvars.example` for configuration options
   - Copy to `terraform.tfvars` and customize values

4. **Initialize**
   ```bash
   terraform init
   ```

5. **Plan**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

6. **Deploy**
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## 📝 Configuration

### Environment Configuration (DEV ↔ PROD)

To change between environments (dev/staging/prod), create a `terraform.tfvars` file:

**Development Environment:**
```hcl
# terraform.tfvars
environment = "dev"
primary_location = "southcentralus"
resource_group_locations = {
  hub    = "southcentralus"
  spoke1 = "brazilsouth"
}
enable_network_watcher = true
enable_ddos_protection = false
```

**Production Environment:**
```hcl
# terraform.tfvars
environment = "prod"
primary_location = "southcentralus"
resource_group_locations = {
  hub    = "southcentralus"
  spoke1 = "brazilsouth"
}
enable_network_watcher = true
enable_ddos_protection = true  # Recommended for production
```

**Option 1: Using terraform.tfvars file (Recommended):**
```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your preferred environment
# Then deploy
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

**Option 2: Using command line variables:**
```bash
# For Production deployment
terraform plan -var="environment=prod" -var="enable_ddos_protection=true"
terraform apply -var="environment=prod" -var="enable_ddos_protection=true"

# For Development deployment
terraform plan -var="environment=dev" -var="enable_ddos_protection=false"
terraform apply -var="environment=dev" -var="enable_ddos_protection=false"

# Multiple variables at once
terraform plan \
  -var="environment=prod" \
  -var="enable_ddos_protection=true" \
  -var="enable_network_watcher=true"
```

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev, staging, prod) | `dev` | No |
| `primary_location` | Primary Azure region | `southcentralus` | No |
| `resource_group_locations` | Resource group locations (names auto-generated) | See variables.tf | No |
| `enable_network_watcher` | Enable Network Watcher | `true` | No |
| `enable_ddos_protection` | Enable DDoS Protection | `false` | No |
| `dns_zones` | List of DNS zones to create | See variables.tf | No |

### DNS Configuration

The project includes DNS zone management with the following features:

- **Private DNS Zones**: Internal domain resolution for VNet resources
- **Public DNS Zones**: External domain resolution 
- **VNet Linking**: Automatic linking of DNS zones to VNets
- **Standardized Naming**: Consistent DNS zone naming following project conventions

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
├── outputs.tf                 # Output values (standardized format)
├── versions.tf                # Provider versions
├── backend.tf                 # Backend configuration
├── provider.tf                # Provider configuration
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore rules
├── README.md                  # This file
└── modules/
    ├── vnet/                  # Generic VNet module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf         # Standardized VNet outputs
    └── dns/                   # DNS zone management module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf         # Standardized DNS outputs
```

## 🔍 Outputs (Standardized Format)

After deployment, you'll get standardized outputs for all resources including:

### Resource Groups
- **Name**: Resource group name
- **ID**: Azure resource ID
- **Location**: Azure region
- **Tags**: Applied tags

### Virtual Networks
- **Name**: VNet name
- **ID**: Azure resource ID
- **Location**: Azure region
- **Resource Group**: Parent resource group
- **Address Space**: CIDR blocks

### Subnets
- **Name**: Subnet name
- **ID**: Azure resource ID
- **Address Prefix**: CIDR block
- **VNet**: Parent VNet name

### Network Security Groups
- **Name**: NSG name  
- **ID**: Azure resource ID
- **Location**: Azure region
- **Resource Group**: Parent resource group

### DNS Zones
- **Name**: DNS zone name
- **ID**: Azure resource ID
- **Type**: Private or Public zone
- **Resource Group**: Parent resource group
- **VNet Links**: Associated VNets (for private zones)

### VNet Peerings
- **Name**: Peering name
- **ID**: Azure resource ID
- **Status**: Peering status
- **Remote VNet**: Target VNet information

All outputs follow a consistent format with relevant information for monitoring, troubleshooting, and integration with other systems.

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

## 🔧 Troubleshooting

### Common Issues

#### Authentication Error
```
Error: building account: unable to configure ResourceManagerAccount: subscription ID could not be determined
```

**Solution**: Ensure you're authenticated with Azure and have a subscription set:

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "your-subscription-id"

# Verify current account
az account show
```

#### Backend Storage Access
If you encounter issues with the backend storage, verify:
1. Storage account exists and is accessible
2. Container 'tfstate' exists
3. ARM_ACCESS_KEY environment variable is set
4. Correct storage account name in backend.tf

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
