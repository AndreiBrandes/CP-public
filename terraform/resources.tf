resource "aws_s3_bucket" "main" {
  bucket = "${local.project_name}-bucket-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "${local.project_name}-bucket"
  }
}
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_sqs_queue" "main" {
  name                      = "${local.project_name}-queue"
  message_retention_seconds  = 86400
  receive_wait_time_seconds = 5
  tags = {
    Name = "${local.project_name}-queue"
  }
}
resource "aws_ssm_parameter" "token" {
  name        = "/devops-exam/token"
  description = "Token for microservice1 validation"
  type        = "SecureString"
  value       = "$DJISA<$#45ex3RtYr"
  tags = {
    Name = "${local.project_name}-token"
  }
}
resource "aws_iam_role" "ecs_task" {
  name = "${local.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${local.project_name}-ecs-task-role"
  }
}
resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = aws_ssm_parameter.token.arn
      }
    ]
  })
}
resource "aws_iam_role" "ecs_execution" {
  name = "${local.project_name}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${local.project_name}-ecs-execution-role"
  }
}
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
