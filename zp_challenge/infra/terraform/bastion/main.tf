########### Bastion host ###################

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Public"
  }
}

resource "random_shuffle" "bastion_subnet" {
  input = data.aws_subnet_ids.public.ids
  result_count = 1
}



resource "aws_key_pair" "bastion" {
  key_name   = "bastion_host"
  public_key = var.public_key
}


resource "aws_instance" "bastion" {
  ami                             = data.aws_ami.ubuntu.id
  instance_type                   = var.instance_type
  key_name                        = aws_key_pair.bastion.key_name
  vpc_security_group_ids          = [ var.bastion_security_group ]
  subnet_id                       = random_shuffle.bastion_subnet.result.0
  associate_public_ip_address 	  = true
  iam_instance_profile		  = var.instance_profile
  user_data_base64 = base64encode(templatefile("${path.module}/scripts/bootstrap.tpl", {rds_user = var.application_db_user, region = var.region}))
  tags = {
    Name = "Bastion Host"
  }
  lifecycle {
    ignore_changes = [subnet_id, user_data_base64, ami]
  }

}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_eip_association" "eip" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.eip.id
}

