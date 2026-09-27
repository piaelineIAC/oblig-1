output "subnet_ids" {
  value       = { for k, s in azurerm_subnet.subnet : k => s.id }
  description = "Subnet-ID per subnettnavn."
}
 
output "subnet_prefixes" {
  value       = { for k, s in azurerm_subnet.subnet : k => s.address_prefixes[0] }
  description = "Utregnet adresseprefiks per subnettnavn."
}
 
output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID-en til det virtuelle nettverket – trengs blant annet til peering."
}
 
output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Navnet på det virtuelle nettverket."
}