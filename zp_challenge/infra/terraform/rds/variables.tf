variable "vpc_id" {
	type = string
}

variable "cluster_name" {
	type = string
}

variable "database_name" {
	type = string
}

variable "master_user" {
	type = string
	default = "root"
}

variable "master_password" {
	type = string
}

variable "backup_retention_period" {
	type = number
	default = 7
}

variable "backup_window" {
	type = string
	default = "01:00-03:00"
}

variable "vpc_security_group_ids" {
	type = list
}

variable "db_instance_type" {
	type = string
	default = "db.r4.large"
}

variable "environment" {
	type = string
}

