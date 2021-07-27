[
  {
    "portMappings": [
      {
        "hostPort": 8000,
        "protocol": "tcp",
        "containerPort": 8000
      }
    ],
    "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${region}",
          "awslogs-stream-prefix": "wagtail"
       }
    },
    "cpu": ${cpu},
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      },
      {
	"name": "SSL_CA_CERT_PATH",
	"value": "/app/rds-combined-ca-bundle.pem"
      },
      {
	"name": "DJANGO_SUPERUSER_USERNAME",
	"value": "${django_user}"
      },
      {
	"name": "DJANGO_SUPERUSER_PASSWORD",
	"value": "${django_password}"
      },
      {
        "name": "DJANGO_SUPERUSER_EMAIL",
        "value": "${django_email}"
      },
      {
	"name": "DB_HOST",
	"value": "${database_host}"
      },
      {
        "name": "DB_USER",
        "value": "${database_user}"
      },
      {
        "name": "DB_NAME",
        "value": "${database_name}"
      }
    ],
    "memory": ${memory},
    "image": "${application_image}",
    "essential": true,
    "name": "wagtail"
  }
]
