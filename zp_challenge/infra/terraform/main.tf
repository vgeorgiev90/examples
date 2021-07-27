locals {
    bastion_proxy = "socks5://${module.bastion.elastic_ip}:1080"
}

provider "mysql" {
    username = var.master_user
    password = var.master_password
    endpoint = module.rds.endpoint
    proxy    = local.bastion_proxy
}

provider "aws" {
	region = var.region
}

module "vpc" {
	source = "./vpc"
	environment = var.environment
	access_ip = var.access_ip
}

module "rds" {
	source = "./rds"
	depends_on = [ module.vpc ]
	environment = var.environment
	vpc_id = module.vpc.vpc_id
	cluster_name = var.cluster_name
	database_name = var.database_name
	master_password = var.master_password
	vpc_security_group_ids = [ module.vpc.security_group_rds ]
}

module "db_user" {
	source = "./db_user"
	depends_on = [module.rds, module.bastion]
	application_db_user = var.application_db_user
	database_name = var.database_name
}

module "iam" {
	source = "./iam"
	depends_on = [ module.rds, module.alb ]
	environment = var.environment
	rds_cluster_identifier = module.rds.cluster_identifier
	alb_arn = module.alb.alb_arn
	region = var.region
}

module "bastion" {
	source = "./bastion"
	depends_on = [ module.vpc, module.iam ]
	region = var.region
	vpc_id = module.vpc.vpc_id
	public_key = var.public_key
	bastion_security_group = module.vpc.security_group_bastion
	instance_profile = module.iam.rds_auth_iam_instance_profile_name
	application_db_user = var.application_db_user
}

module "alb" {
	source = "./alb"
	depends_on = [ module.vpc ]
	environment = var.environment
	vpc_id = module.vpc.vpc_id
	load_balancer_sg = module.vpc.security_group_alb
	acm_certificate_arn = var.acm_certificate_arn
}

module "ecs" {
	source = "./ecs"
	depends_on = [ module.vpc, module.alb, module.iam, module.bastion ]
	environment = var.environment
	vpc_id = module.vpc.vpc_id
	ecs_sg = module.vpc.security_group_generic
	ecs_target_group = module.alb.ecs_target_group_arn
	ecs_role = module.iam.rds_auth_iam_role_arn
	cpu = var.cpu_limit
	memory = var.memory_limit
	region = var.region
	database_host = module.rds.endpoint
	database_user = var.application_db_user
	database_name = var.database_name
	application_image = var.application_image
	django_user = var.django_user
	django_password = var.django_password
	django_email = var.django_email
}

module "auto_scaling" {
	source = "./auto_scaling"
	depends_on = [ module.vpc, module.ecs ]
	environment = var.environment
	ecs_cluster = module.ecs.ecs_cluster
	ecs_service = module.ecs.ecs_service
}
