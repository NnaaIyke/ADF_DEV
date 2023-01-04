

# This is the provider for the Azure #

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.3.0"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
      version = "0.2.2"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "bcb84c96-57ea-424d-bf13-7a36ba28eb8d"
}

provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/Data-Integrations"
  personal_access_token =  "sikng5kjnr6fh4laonov35tsbxeoudzwpjh7zgasldhs3bla4apq"
}
