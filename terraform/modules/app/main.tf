variable "name" {
  type        = string
  description = "Application name prefix"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "key_vault_public_access_enabled" {
  description = "Allow public network access to Key Vault"
  type        = bool
}

variable "key_vault_secret_versionless_id" {
  description = "Versionless URI of a pre-provisioned Key Vault secret"
  type        = string
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID"
}

variable "replica_min" {
  type        = number
  description = "Minimum application replicas"
}

variable "replica_max" {
  type        = number
  description = "Maximum application replicas"
}

variable "key_vault_purge_protection" {
  type        = bool
  description = "Enable Key Vault purge protection"
}

variable "allow_public_ingress" {
  type        = bool
  description = "Allow public application ingress"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_key_vault" "app" {
  name                = substr(replace("${var.name}-kv", "-", ""), 0, 24)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  purge_protection_enabled      = var.key_vault_purge_protection
  public_network_access_enabled = var.key_vault_public_access_enabled

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "app_key_vault_reader" {
  scope                = azurerm_key_vault.app.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_container_app_environment" "app" {
  name                       = "${var.name}-environment"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}

resource "azurerm_container_app" "app" {
  name                         = "${var.name}-app"
  container_app_environment_id = azurerm_container_app_environment.app.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  template {
    min_replicas = var.replica_min
    max_replicas = var.replica_max

    container {
      name   = "web"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "APP_SECRET"
        secret_name = "app-secret"
      }
    }
  }

  secret {
    name                = "app-secret"
    key_vault_secret_id = var.key_vault_secret_versionless_id
    identity            = azurerm_user_assigned_identity.app.id
  }

  ingress {
    external_enabled = var.allow_public_ingress
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [azurerm_role_assignment.app_key_vault_reader]

  tags = var.tags
}

output "min_replicas" {
  description = "Minimum number of application replicas"
  value       = azurerm_container_app.app.template[0].min_replicas
}

output "key_vault_purge_protection_enabled" {
  description = "Whether Key Vault purge protection is enabled"
  value       = azurerm_key_vault.app.purge_protection_enabled
}

output "key_vault_public_access_enabled" {
  description = "Whether public network access to Key Vault is enabled"
  value       = azurerm_key_vault.app.public_network_access_enabled
}