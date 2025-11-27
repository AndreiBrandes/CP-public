resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = {
    Name = "${local.project_name}-cluster"
  }
}
resource "aws_cloudwatch_log_group" "ms1" {
  name              = "/ecs/${local.project_name}-ms1"
  retention_in_days = 7
  tags = {
    Name = "${local.project_name}-ms1-logs"
  }
}
resource "aws_cloudwatch_log_group" "ms2" {
  name              = "/ecs/${local.project_name}-ms2"
  retention_in_days = 7
  tags = {
    Name = "${local.project_name}-ms2-logs"
  }
}
resource "aws_ecs_task_definition" "ms1" {
  family                   = "${local.project_name}-ms1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name  = "microservice1"
      image = "oholic/microservice1:latest"
      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "5000"
        },
        {
          name  = "AWS_REGION"
          value = "eu-north-1"
        },
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.main.url
        },
        {
          name  = "SSM_TOKEN_PARAM"
          value = "/devops-exam/token"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ms1.name
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  tags = {
    Name = "${local.project_name}-ms1-task"
  }
}
resource "aws_ecs_task_definition" "ms2" {
  family                   = "${local.project_name}-ms2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name  = "microservice2"
      image = "oholic/microservice2:latest"
      environment = [
        {
          name  = "AWS_REGION"
          value = "eu-north-1"
        },
        {
          name  = "POLL_INTERVAL"
          value = "10"
        },
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.main.url
        },
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.main.id
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ms2.name
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  tags = {
    Name = "${local.project_name}-ms2-task"
  }
}
resource "aws_ecs_service" "ms1" {
  name            = "${local.project_name}-ms1"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ms1.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ms1.arn
    container_name   = "microservice1"
    container_port   = 5000
  }
  depends_on = [aws_lb_listener.main]
  tags = {
    Name = "${local.project_name}-ms1-service"
  }
}
resource "aws_ecs_service" "ms2" {
  name            = "${local.project_name}-ms2"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ms2.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  tags = {
    Name = "${local.project_name}-ms2-service"
  }
}
