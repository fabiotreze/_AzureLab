terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-eus2"
    storage_account_name = "tfstate173313992"
    container_name       = "tfstate"
    key                  = "project1-terraform.tfstate"
    # Use ARM_ACCESS_KEY environment variable or authenticate via Azure CLI
  }
}
