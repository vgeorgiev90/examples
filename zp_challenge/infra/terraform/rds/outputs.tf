output "endpoint" {
	value = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
	value = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_identifier" {
	value = aws_rds_cluster.aurora.cluster_resource_id
}

