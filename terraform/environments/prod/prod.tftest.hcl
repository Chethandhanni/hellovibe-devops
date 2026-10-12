mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      client_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      object_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}


run "prod_security_and_scaling" {
  command = plan

  assert {
    condition     = module.app.min_replicas >= 2
    error_message = "Production must run at least two minimum replicas."
  }

  assert {
    condition     = module.app.key_vault_purge_protection_enabled == true
    error_message = "Production Key Vault must enable purge protection."
  }

  assert {
    condition     = module.app.key_vault_public_access_enabled == false
    error_message = "Production Key Vault public network access must be disabled."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["project"] == "hellovibe"
    error_message = "Production resource group must have the project tag."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["environment"] == "prod"
    error_message = "Production resource group must have the prod environment tag."
  }
}
