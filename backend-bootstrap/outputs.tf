output "backend_hcl_template" {
  value = <<EOT
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.tfstate.name}"
use_azuread_auth     = true
EOT
}