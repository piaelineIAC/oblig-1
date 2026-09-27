variable "subscription_id" {
  type        = string
  default     = null
  description = "Subscription-ID. Står den som null, brukes ARM_SUBSCRIPTION_ID."

}

variable "shortname" {
  type        = string
  description = "Personlig kortnavn"
}

variable "project" {
  type        = string
  default     = "oppg4"
  description = "Prosjektnavnet som inngår i alle ressursnavn."
}

variable "environment" {
  type        = string
  description = "Miljønavnet: dev, test eller prod."

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment må være dev, test eller prod."
  }
}

variable "location" {
  type        = string
  default     = "norwayeast"
  description = "Azure-regionen ressursene opprettes i."

  validation {
    condition = contains([
      "northeurope", "uksouth", "westeurope", "norwayeast", "norwaywest",
    ], var.location)
    error_message = "Bare disse regionene er tillatt i tenanten vår."
  }
}

variable "vm_subnet_key" {
  type        = string
  default     = "app"
  description = "Nøkkelen i nettverkets subnet_ids-output som VM-en skal bruke."

}

variable "vm_size" {
  type        = string
  description = "VM-SKU for dette miljøet."
}

variable "backend_storage_account_name" {
  type        = string
  description = "Navnet på storage account som inneholder nettverksstate."
}

variable "backend_container_name" {
  type        = string
  description = "Navnet på containeren som inneholder nettverksstate."
}

variable "backend_resource_group_name" {
  type        = string
  description = "Navnet på ressursgruppa som inneholder storage account med nettverksstate."
}

variable "admin_username" {
  type        = string
  default     = "tfadmin"
  description = "Lokal administratorbruker på VM-en."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Administratorpassord hentet fra Key Vault."
}
