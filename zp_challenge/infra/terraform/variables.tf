variable "region" {
	type = string
	default = "eu-west-1"
}

variable "environment" {
	type = string
	description = "Environment prefix for resources"
}

variable "cluster_name" {
	type = string
	description = "RDS Cluster name"
}

variable "database_name" {
	type = string
	description = "RDS database to be created"
}

variable "master_user" {
	type = string
	default = "root"
	description = "RDS master username"
}

variable "master_password" {
	type = string
	description = "RDS password for the master user"
}

variable "public_key" {
	type = string
	description = "Public key which will be added to the bastion instancs"
}

variable "application_db_user" {
	type = string
	description = "RDS database user to be created"
}

variable "access_ip" {
	type = string
	description = "IP from which you will run this terraform provisioning, its whitelisted on the bastion security group for SSH and SOCKS5 proxy dont get it wrong or the provisioning of Database resources will fail"
}

variable "acm_certificate_arn" {
	type = string
	description = "ARN of the ACM certificate which will be used for the load balancer either request a new one from the AWS console or import one"
}

variable "cpu_limit" {
	type = string
	description = "CPU limit for the ECS task, consult the AWS docs for allowed combinations"
}

variable "memory_limit" {
	type = string
	description = "Memory limit for the ECS task consult the AWS docs for allowed combinations"
}

variable "application_image" {
        type = string
	description = "Application image to be used in the format REPOSITORY:TAG (You can build one with the builder.py script)"
}

variable "django_user" {
        type = string
	description = "Django superuser name"
}

variable "django_password" {
        type = string
	description = "Django superuser password"
}

variable "django_email" {
        type = string
	description = "Django superuser email address"
}

