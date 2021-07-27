output "rds_auth_iam_role_arn" {
	value = aws_iam_role.rds_iam_auth_role.arn
}

output "rds_auth_iam_role_name" {
	value = aws_iam_role.rds_iam_auth_role.name
}

output "rds_auth_iam_instance_profile_arn" {
	value = aws_iam_instance_profile.rds_iam_auth.arn
}

output "rds_auth_iam_instance_profile_name" {
        value = aws_iam_instance_profile.rds_iam_auth.name
}

