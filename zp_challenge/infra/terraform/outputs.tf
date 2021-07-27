output "bastion_elastic_ip" {
	value = module.bastion.elastic_ip
}

output "rds_endpoint" {
	value = module.rds.endpoint
}

output "alb_dns_name" {
	value = module.alb.elb_dns_name
}
