# ECS Resources

Resources included:
* Elastic Container Service cluster based on FARGATE capacity provider
* Template based ECS task definition
* ECS Service to be deployed inside the cluster with launch type FARGATE
* AWS Cloudwatch log group for the ECS container logs


Notes:
Container definition is located in tasks/ecs_task.tpl as a terraform template
