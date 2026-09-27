variable "rg_name" {
  type        = string
  description = "Navnet på ressursgruppa maskinen skal ligge i."
}
 
variable "location" {
  type        = string
  description = "Azure-regionen ressursene opprettes i."
}
 
variable "base_name" {
  type        = string
  description = "Navnegrunnlaget miljøet leverer. Modulen setter selv på 'nic-' og 'vm-'."
}
 
variable "subnet_id" {
  type        = string
  description = <<-TEKST
    ID-en til subnettet nettverkskortet skal ligge i.
    Kommer fra nettverksmodulens output – aldri skrevet inn for hånd.
  TEKST
}
 
variable "vm_size" {
  type        = string
  description = "VM-SKU, f.eks. Standard_B2as_v2. Se lista over tillatte SKU-er i oppgaven."
 
  validation {
    condition = contains([
      "Standard_B2as_v2", "Standard_B4as_v2",
      "Standard_D2s_v5", "Standard_D4s_v5",
      "Standard_D2s_v6", "Standard_D4s_v6",
      "Standard_E2s_v5", "Standard_E4s_v5",
      "Standard_E2s_v6", "Standard_E4s_v6",
    ], var.vm_size)
    error_message = "vm_size må være en av de tillatte x86-64-SKU-ene i tenanten vår."
  }
}
 
variable "admin_username" {
  type        = string
  default     = "tfadmin"
  description = "Lokal administratorbruker på maskinen."
}
 
variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Passord for administratorbrukeren."
   
 
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Azure krever minst 12 tegn i admin_password."
  }
}
 
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Felles tags fra miljøet."
}