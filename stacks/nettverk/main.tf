terraform {
  required_version = ">= 1.5.0"
  backend "azurerm"{}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
 
provider "azurerm" {
  features {}
  
 
  # azurerm 4.x vil vite hvilken subscription den skal jobbe mot. Lar du
  # variabelen stå som null, plukkes verdien fra miljøvariabelen
  # ARM_SUBSCRIPTION_ID eller fra den aktive subscriptionen i `az account show`.
  # Har du flere subscriptions, sett den eksplisitt i terraform.tfvars.
  subscription_id = var.subscription_id
}
 
locals {
  # Miljøet leverer BESTANDDELENE til navnet – hvem, hvilket prosjekt, hvilket
  # miljø. Modulene setter dem sammen til ferdige ressursnavn.
  #
  # Skillet er verdt å holde fast på: her nede vet vi at vi er "dev" og at
  # prosjektet heter "oppg3". Vi vet IKKE at et subnet skal ha snet-prefiks,
  # eller at en Windows-maskin bare tåler 15 tegn i computer_name. Den
  # kunnskapen hører hjemme i modulen som eier ressurstypen.
  base_name = lower(format("%s-%s-%s", var.project, var.environment, var.shortname))
 
  # Felles tags. Miljøet eier disse, fordi det er miljøet som avgjør hva de
  # skal si. Husk at tags IKKE arves fra ressursgruppa til ressursene inne i
  # den – hver ressurs må ha linja selv, og derfor sendes mapet nedover.
  tags = {
    environment = var.environment
    owner       = var.shortname
    project     = var.project
    managedby   = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s", local.base_name)
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"
 
  rg_name        = azurerm_resource_group.rg.name
  location       = var.location
  base_name      = local.base_name
  address_space  = var.address_space
  subnets        = var.subnets
  subnet_newbits = var.subnet_newbits
  tags           = local.tags
}
