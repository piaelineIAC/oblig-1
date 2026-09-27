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

variable "address_space" {
  type        = string
  description = "Adresserommet dette miljøet bruker."
}
 
variable "subnets" {
  type        = map(number)
  description = "Subnett: navn => netnum."
}
 
variable "subnet_newbits" {
  type        = number
  default     = 8
  description = "Antall bit subnettene forlenger adresserommet med."
}

variable "vm_subnet_key" {
  type        = string
  default     = "app"
 
}
 
variable "vm_size" {
  type        = string
  description = "VM-SKU for dette miljøet."
}
