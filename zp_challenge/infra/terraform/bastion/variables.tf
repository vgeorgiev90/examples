variable "vpc_id" {
	type = string
}

variable "public_key" {
	type = string
}

variable "instance_type" {
	type = string
	default = "t2.micro"
}

variable "bastion_security_group" {
	type = string
}

variable "instance_profile" {
	type = string
}

variable "application_db_user" {
	type = string
}

variable "region" {
	type = string
}

