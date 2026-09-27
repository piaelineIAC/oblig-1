provider "azurerm" {
  features {}
  storage_use_azuread = true
  subscription_id     = var.subscription_id
}

data "azurerm_client_config" "current" {}

locals {
  tags = {
    keep      = "true" # freder ressursgruppa mot nattlig sletting
    purpose   = "terraform-backend"
    owner     = var.shortname
    managedby = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = format("rg-tfstate-%s", var.shortname)
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "sa" {
  name                      = format("sa%s", var.shortname)
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  tags                      = local.tags
  shared_access_key_enabled = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_key_vault" "kv" {
  name                       = format("kv-%s", var.shortname)
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  tags                       = local.tags
  rbac_authorization_enabled = true
}


# Gir GitHub Actions tilgang til å lese og skrive Terraform-state.
resource "azurerm_role_assignment" "github_state" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.github_principal_object_id
  principal_type       = "ServicePrincipal"
}

# Gir GitHub Actions tilgang til å lese secrets fra Key Vault.
resource "azurerm_role_assignment" "github_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.github_principal_object_id
  principal_type       = "ServicePrincipal"
}

# Lar din innloggede bruker legge inn og oppdatere secrets.
resource "azurerm_role_assignment" "user_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}
