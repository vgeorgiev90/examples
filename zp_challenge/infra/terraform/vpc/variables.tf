variable "vpc_cidr" {
  type = string
  default = "192.168.0.0/16"
  description = "VPC CIDR range"
}

variable "public_subnet_cidrs" {
  type = list
  default = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  description = "CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type = list
  default = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
  description = "CIDR blocks for private subnets"
}

variable "environment" {
  type = string
  default = "Staging"
}

variable "public_count" {
  type = number
  default = 3
}

variable "private_count" {
  type = number
  default = 3
}

variable "access_ip" {
  type = string
  default = "0.0.0.0/0"
}
