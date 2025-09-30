provider "azurerm" {
  features {}
  
  # Subscription ID from active Azure account
  # Use environment variables for other authentication:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
  # Or authenticate using Azure CLI: az login
}