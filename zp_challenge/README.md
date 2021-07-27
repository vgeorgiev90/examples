# zp_challenge

This stack is used to build and deploy wagtail django application on AWS ECS fargate with RDS aurora(mysql) database and RDS IAM authentication.
Automatic scaling is included for the ECS service and a public load balancer with https only traffic.


What this stack manage:
* VPC, private and public subnets, security groups, internet gateway, nat gateway
* RDS Cluster with enabled IAM authentication
* MySQL user with AWS IAM based authentication
* ECS fargate cluster with automatic scaling based on memory and cpu tresholds
* Cloudwatch log group for ECS service that is deployed
* Bastion hosts for infrastructure inspection and debugging

What is not included, but required:
* DNS management
* AWS ACM certificate either purchase from aws or import, but ACM certificate ARN is required


Directory structure:
* infra/    ->  All terraform modules and code
* bin/      ->  Management script
* project/  ->  Application source



The Application choosed and deployed is python CMS called Wagtail which is based on django. 
Ref: https://wagtail.io/

Some small changes are made to the project so it can support RDS IAM based authentication.
python modules added: 
mysqlclient   		->   MySQL python library
django-iam-dbauth	->   Django library for RDS IAM authentication, ref: https://github.com/labd/django-iam-dbauth
django-request-logging  ->   Django library for request logging, ref: https://github.com/Rhumbix/django-request-logging


Deployment requirements:
* Python3, python3-pip
* terraform > 0.13
* docker
* awscli 
* valid AWS credentials(keep in mind that IAM resources are created so make sure that you have enough permissions to do so)

Python modules:
* boto3
* docker


Notes:
Before the infrastructure provisioning you will need to create ECR registry, build the application image and push it. bin/builder.py script can be used to do so.


TODO:
* Improve the builder.py script and maybe add additional functionalities like a simple wrapper for terraform apply
* Add more terraform outputs
* Add support for existing vpc
* Add route53 dns management with terraform, and/or cloudflare dns management with python
* More descriptive variable names and READMEs 
