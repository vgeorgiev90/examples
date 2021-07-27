################## IAM resources ##################

data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "rds_iam_auth" {
  name = "rds_iam_auth-${var.environment}"
  role = aws_iam_role.rds_iam_auth_role.name
}

################# RDS IAM connenction policy ##############

resource "aws_iam_role_policy" "secrets_storage" {
  name = "secrets_storage_rds_creds-${var.environment}"
  role = aws_iam_role.rds_iam_auth_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
            ]
        }
    ]
}
EOF
}

####################### Secrets manager policy (not used but good to be here :) ) ######################

resource "aws_iam_role_policy" "rds_iam_auth_policy" {
  name = "rds_iam_auth_policy-${var.environment}"
  role = aws_iam_role.rds_iam_auth_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds-db:connect"
            ],
            "Resource": [
                "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_cluster_identifier}/*"
            ]
        }
    ]
}
EOF
}


######################## ECS policies (cloudwatch, alb, ecr ) #########################

data "aws_iam_policy_document" "ecs_service_elb" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]

    resources = [
      var.alb_arn
    ]
  }
}

data "aws_iam_policy_document" "ecs_service_standard" {

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeTags",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "ecs_service_scaling" {

  statement {
    effect = "Allow"

    actions = [
      "application-autoscaling:*",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:EnableAlarmActions",
      "iam:CreateServiceLinkedRole",
      "sns:CreateTopic",
      "sns:Subscribe",
      "sns:Get*",
      "sns:List*"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "ecs_service_logging" {

  statement {
     effect = "Allow"

     actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ]

    resources = [
        "arn:aws:logs:*:*:*"
    ]
  }
}


data "aws_iam_policy_document" "ecs_container_registry" {

  statement {
     effect = "Allow"

     actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken"
    ]

    resources = [
        "*"
    ]
  }
}


resource "aws_iam_policy" "ecs_container_registry" {
  name = "ecs-ecr"
  path = "/"
  description = "Allow access to ECR registries"

  policy = data.aws_iam_policy_document.ecs_container_registry.json
}

resource "aws_iam_policy" "ecs_service_logs" {
  name = "ecs-logs"
  path = "/"
  description = "Allow access to cloudwatch log groups"
 
  policy = data.aws_iam_policy_document.ecs_service_logging.json
}

resource "aws_iam_policy" "ecs_service_elb" {
  name = "ecs-elb"
  path = "/"
  description = "Allow access to the service elb"

  policy = data.aws_iam_policy_document.ecs_service_elb.json
}

resource "aws_iam_policy" "ecs_service_standard" {
  name = "ecs-standard"
  path = "/"
  description = "Allow standard ecs actions"

  policy = data.aws_iam_policy_document.ecs_service_standard.json
}

resource "aws_iam_policy" "ecs_service_scaling" {
  name = "ecs-scaling"
  path = "/"
  description = "Allow ecs service scaling"

  policy = data.aws_iam_policy_document.ecs_service_scaling.json
}

resource "aws_iam_role_policy_attachment" "ecs_container_registry" {
  role = aws_iam_role.rds_iam_auth_role.name
  policy_arn = aws_iam_policy.ecs_container_registry.arn
}

resource "aws_iam_role_policy_attachment" "ecs_service_logging" {
  role = aws_iam_role.rds_iam_auth_role.name
  policy_arn = aws_iam_policy.ecs_service_logs.arn
}


resource "aws_iam_role_policy_attachment" "ecs_service_elb" {
  role = aws_iam_role.rds_iam_auth_role.name
  policy_arn = aws_iam_policy.ecs_service_elb.arn
}

resource "aws_iam_role_policy_attachment" "ecs_service_standard" {
  role = aws_iam_role.rds_iam_auth_role.name
  policy_arn = aws_iam_policy.ecs_service_standard.arn
}

resource "aws_iam_role_policy_attachment" "ecs_service_scaling" {
  role = aws_iam_role.rds_iam_auth_role.name
  policy_arn = aws_iam_policy.ecs_service_scaling.arn
}



######################### role for bastion and ecs ##########################

resource "aws_iam_role" "rds_iam_auth_role" {
  name = "rds_iam_auth_role-${var.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
		"ec2.amazonaws.com",
		"ecs-tasks.amazonaws.com",
		"ecs.amazonaws.com"
	]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


