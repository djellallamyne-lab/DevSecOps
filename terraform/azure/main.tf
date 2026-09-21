# Azure target infrastructure (OPTIONAL apply)
# Same pipeline artefacts; different registry/runtime/secrets.
#
# Prerequisites:
#   az login
#   terraform init
#   cp terraform.tfvars.example terraform.tfvars   # fill values, never commit
#   terraform plan
#   terraform apply   # incurs Azure cost

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

variable "prefix" {
  type        = string
  description = "Short prefix for resource names"
  default     = "devsecops"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name = "${var.prefix}-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-${local.name}"
  location = var.location
  tags = {
    project = "devsecops-lab"
    env     = "target-prod"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = replace("acr${local.name}", "-", "")
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.name}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  dns_prefix          = local.name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = {
    project = "devsecops-lab"
  }
}

# Allow AKS kubelet identity to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = substr(replace("kv${local.name}", "-", ""), 0, 24)
  location                   = azurerm_resource_group.lab.location
  resource_group_name        = azurerm_resource_group.lab.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = {
    project = "devsecops-lab"
  }
}

output "resource_group" {
  value = azurerm_resource_group.lab.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.lab.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
