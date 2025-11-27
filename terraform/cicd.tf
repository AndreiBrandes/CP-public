resource "aws_codebuild_project" "ci" {
  name          = "${local.project_name}-ci"
  description   = "CI pipeline for building and pushing Docker images"
  build_timeout = 60
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable {
      name  = "DOCKERHUB_USER"
      value = "oholic"
    }
    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = var.dockerhub_password
      type  = "PLAINTEXT"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
  tags = {
    Name = "${local.project_name}-ci"
  }
}
resource "aws_codebuild_project" "cd" {
  name          = "${local.project_name}-cd"
  description   = "CD pipeline for deploying to ECS"
  build_timeout = 60
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "eu-north-1"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "deploy-buildspec.yml"
  }
  tags = {
    Name = "${local.project_name}-cd"
  }
}
resource "aws_s3_bucket" "source_code" {
  bucket = "${local.project_name}-source-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "${local.project_name}-source"
  }
}
resource "aws_s3_bucket_versioning" "source_code" {
  bucket = aws_s3_bucket.source_code.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_codepipeline" "main" {
  name     = "${local.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        S3Bucket             = aws_s3_bucket.source_code.id
        S3ObjectKey          = "source.zip"
        PollForSourceChanges = "false"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.ci.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.cd.name
      }
    }
  }
  tags = {
    Name = "${local.project_name}-pipeline"
  }
}
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${local.project_name}-codepipeline-artifacts-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "${local.project_name}-codepipeline-artifacts"
  }
}
resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_iam_role" "codebuild" {
  name = "${local.project_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${local.project_name}-codebuild-role"
  }
}
resource "aws_iam_role_policy" "codebuild" {
  name = "${local.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-north-1:*:log-group:/aws/codebuild/${local.project_name}*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
          "${aws_s3_bucket.source_code.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task.arn,
          aws_iam_role.ecs_execution.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "codepipeline" {
  name = "${local.project_name}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${local.project_name}-codepipeline-role"
  }
}
resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.project_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
          "${aws_s3_bucket.source_code.arn}/*",
          aws_s3_bucket.codepipeline_artifacts.arn,
          aws_s3_bucket.source_code.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [
          aws_codebuild_project.ci.arn,
          aws_codebuild_project.cd.arn
        ]
      }
    ]
  })
}
resource "aws_cloudwatch_log_group" "codebuild_ci" {
  name              = "/aws/codebuild/${local.project_name}-ci"
  retention_in_days = 7
  tags = {
    Name = "${local.project_name}-codebuild-ci-logs"
  }
}
resource "aws_cloudwatch_log_group" "codebuild_cd" {
  name              = "/aws/codebuild/${local.project_name}-cd"
  retention_in_days = 7
  tags = {
    Name = "${local.project_name}-codebuild-cd-logs"
  }
}
