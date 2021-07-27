output "vpc_id" {
  value = aws_vpc.cb_vpc.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "public" {
  value = aws_subnet.public.*.id
}

output "available_zones" {
  value = aws_subnet.public.*.availability_zone
}

output "security_group_generic" {
  value = aws_security_group.generic.id
}

output "security_group_rds" {
  value = aws_security_group.rds.id
}

output "security_group_bastion" {
  value = aws_security_group.bastion.id
}

output "security_group_alb" {
  value = aws_security_group.load_balancer.id
}
