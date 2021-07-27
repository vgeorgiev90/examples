############# Private subnets data #############

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
  }
}

locals {
  subnet_list = tolist(data.aws_subnet_ids.private.ids)
}


############# RDS subnet group ##################

resource "aws_db_subnet_group" "db_group" {
  name       = "db_subnet_group"
  subnet_ids = local.subnet_list

  tags = {
    Name = "RDS_private_subnets_group"
  }
}


resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = var.cluster_name
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  db_subnet_group_name    = aws_db_subnet_group.db_group.name
  database_name           = var.database_name
  master_username         = var.master_user
  master_password         = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  iam_database_authentication_enabled = true
  vpc_security_group_ids  = var.vpc_security_group_ids
  skip_final_snapshot	  = true
  apply_immediately	  = true
}


resource "aws_rds_cluster_instance" "rds_instances" {
  count              = 2
  identifier         = "${var.cluster_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.db_instance_type
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  db_subnet_group_name = aws_db_subnet_group.db_group.name
}




