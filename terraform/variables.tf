variable "infra_environment" {
  type = string
}

variable "infra_version" {
  type = string
}

variable "resource_category" {
  type = string
  default = "infrastructure"
}

variable "az_use_count" {
  type = number
  default = 2
}
