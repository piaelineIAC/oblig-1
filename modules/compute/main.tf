# =============================================================================
#  modules/compute/  –  compute-komponenten
# -----------------------------------------------------------------------------
#  Nettverkskort og virtuell maskin. Modulen får subnet-ID-en utlevert og slår
#  den aldri opp selv – den vet ikke engang at det finnes en nettverksmodul.
#  Det er den egenskapen som gjør at den kan gjenbrukes et helt annet sted.
# =============================================================================
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
 
locals {
  # Windows godtar maks 15 tegn i computer_name – en arv fra NetBIOS – og
  # ingen bindestreker. Azure-ressursnavnet kan være mye lengre.
  #
  # Dette er nøyaktig den typen kunnskap som HØRER HJEMME I MODULEN (K7).
  # Miljømappa skal slippe å vite at nettopp Windows-maskiner har denne
  # regelen. Legger du navnebyggingen i miljømappa, må hver eneste miljømappe
  # kunne navnereglene for alt stacken inneholder.
  #
  # replace() fjerner bindestrekene, substr() klipper til 15 tegn:
  #   "oppg3-dev-tim" -> "oppg3devtim"
  computer_name = substr(replace(var.base_name, "-", ""), 0, 15)
}
 
resource "azurerm_network_interface" "nic" {
  name                = format("nic-%s", var.base_name)
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
 
  ip_configuration {
    name = "internal"
 
    # Subnettet kommer inn som en variabel. Modulen har ingen data-blokk som
    # leter det opp, og ingen ID skrevet inn for hånd – den får det utlevert
    # av den som setter komponentene sammen.
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}
 
resource "azurerm_windows_virtual_machine" "vm" {
  name                = format("vm-%s", var.base_name)
  computer_name       = local.computer_name
  location            = var.location
  resource_group_name = var.rg_name
 
  # Størrelsen kommer utenfra – det er den som skiller dev fra prod.
  size = var.vm_size
 
  admin_username = var.admin_username
  admin_password = var.admin_password
 
  # Merk hakeparentesene: en VM kan ha flere nettverkskort, så argumentet er
  # en liste selv når vi bare har ett.
  network_interface_ids = [azurerm_network_interface.nic.id]
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
 
  tags = var.tags
}