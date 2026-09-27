# =============================================================================
#  modules/compute/outputs.tf
# =============================================================================
 
output "vm_name" {
  value       = azurerm_windows_virtual_machine.vm.name
  description = "Navnet på den virtuelle maskinen."
}
 
output "vm_id" {
  value       = azurerm_windows_virtual_machine.vm.id
  description = "Azure-ID-en til maskinen."
}
 
output "private_ip_address" {
  value       = azurerm_network_interface.nic.private_ip_address
  description = "Den private IP-adressen maskinen fikk i subnettet sitt."
 
  # Nyttig å se: adressen ligger alltid innenfor prefikset cidrsubnet() regnet
  # ut, og starter aldri lavere enn .4 – Azure reserverer de fire første
  # adressene og den siste i hvert eneste subnet.
}