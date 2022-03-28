# Use an Azure Storage Account for Terraform State
# Can use terraform to create this but assumes pre-existence
terraform {
  backend "azurerm" {
    resource_group_name   = "terraformstate"
    storage_account_name  = "prodtfkhe7pnyx"
    container_name        = "prod-tfstate"
    key                   = "prod/example/aks/terraform.tfstate"
    access_key            = ""
  }
}

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "./modules/resource_group"

  name      = "rg-example-prod-scus"
  location  = "southcentralus"
}

module "virtual_network" {
  source = "./modules/virtual_network"

  vnet_name       = "virtual_network-example-prod-scus"
  resource_group  = module.resource_group.name
  location        = module.resource_group.location
  address_space   = "172.16.0.0/16"
  
  depends_on = [module.resource_group]
}

module "subnet" {
  source = "./modules/subnet"

  subnet_name     = "subnet-example-prod-scus"
  resource_group  = module.resource_group.name
  subnet_cidr     = "172.16.0.0/24"
  vnet_name       = module.virtual_network.vnet_name

  depends_on = [module.virtual_network]
}

module "kubernetes_cluster" {
  source = "./modules/kubernetes_cluster"

  aks_name                = "aks-example-prod-scus"
  azure_region            = module.resource_group.location
  resource_group          = module.resource_group.name
  subnet_id               = module.subnet.id
  worker_pool_name        = "workerpool1"
  worker_pool_vm_size     = "Standard_D2_v3"
  worker_pool_node_count  = "2"
  ingressip_name          = "pip-ingress-aks-example-prod-scus"

  depends_on = [module.subnet]
}
