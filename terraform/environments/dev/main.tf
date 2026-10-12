variable "location" {
  type    = string
  default = "westeurope"
}

locals {
  environment = "dev"
  name        = "hellovibe-dev"
  tags = {
    project     = "hellovibe"
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "../../modules/networking"

  name                = local.name
  environment         = local.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.10.0.0/16"]

  subnets = {
    app = { address_prefixes = ["10.10.1.0/24"] }
  }

  tags = local.tags
}

module "observability" {
  source = "../../modules/observability"

  name                = "${local.name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  tags                = local.tags
}

module "app" {
  source = "../../modules/app"

  name                            = local.name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  log_analytics_workspace_id      = module.observability.workspace_id
  replica_min                     = 1
  replica_max                     = 2
  key_vault_purge_protection      = false
  key_vault_public_access_enabled = true
  key_vault_secret_versionless_id = "https://example.vault.azure.net/secrets/app-secret"
  allow_public_ingress            = true
  tags                            = local.tags
}
