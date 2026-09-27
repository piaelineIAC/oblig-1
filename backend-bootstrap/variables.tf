variable "shortname" {
  type = string
}

variable "location" {
  type    = string
  default = "norwayeast"
}

variable "subscription_id" {
  type    = string
  default = null
}

# Object-ID til service principal-en som GitHub Actions bruker.
variable "github_principal_object_id" {
  description = "Object-ID til GitHub Actions sin service principal"
  type        = string
}
