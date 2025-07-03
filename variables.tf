variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "vpc_tags" {
  type = map(string)
  default = {}
}

variable "igw_tags" {
  type = map(string)
  default = {}
}

variable "public_subnet_tags" {
  type = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type = map(string)
  default = {}
}
variable "database_subnet_tags" {
  type = map(string)
  default = {}
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "database_subnet_cidrs" {
  type = list(string)
}

variable "eip_tags" {
    type = map(string)
    default = {}
}

variable "nat_tags" {
  type = map(string)
  default = {}
}

variable "public_route" {
  type = map(string)
  default = {}
}

variable "private_route" {
  type = map(string)
  default = {}
}

variable "database_route" {
  type = map(string)
  default = {}
}

variable "is_vpc_required" {
  default = false
}

variable "vpc_peering_tags" {
  type = map(string)
  default = {}

}