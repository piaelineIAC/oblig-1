output "subnet_ids" {
  value       = module.network.subnet_ids
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
