variable "ecs_cluster" {
	type = string
}

variable "ecs_service" {
	type = string
}

variable "environment" {
	type = string
}

variable "max_capacity" {
	type = number
	default = 1000
}

variable "min_capacity" {
	type = number
	default = 1
}
