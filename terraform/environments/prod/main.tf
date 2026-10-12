variable "location" {
  type    = string
  default = "westeurope"
}

locals {
  environment = "prod"
  name        = "hellovibe-prod"
  tags = {
    project     = "hellovibe"
    environment = "prod"
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
  address_space       = ["10.20.0.0/16"]

  subnets = {
    app = { address_prefixes = ["10.20.1.0/24"] }
  }

  tags = local.tags
}

module "observability" {
  source = "../../modules/observability"

  name                = "${local.name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 90
  tags                = local.tags
}

module "app" {
  source = "../../modules/app"

  name                            = local.name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  log_analytics_workspace_id      = module.observability.workspace_id
  replica_min                     = 2
  replica_max                     = 5
  key_vault_purge_protection      = true
  key_vault_public_access_enabled = false
  key_vault_secret_versionless_id = "https://example.vault.azure.net/secrets/app-secret"
  allow_public_ingress            = false
  tags                            = local.tags
}
