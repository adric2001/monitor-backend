terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
}

resource "aws_dynamodb_table" "metrics_table" {
  name           = "SystemMetrics"
  billing_mode   = "PAY_PER_REQUEST" 
  hash_key       = "host_id"    
  range_key      = "timestamp"  

  attribute {
    name = "host_id"
    type = "S" # String
  }

  attribute {
    name = "timestamp"
    type = "S" # String
  }

  tags = {
    Environment = "Production"
    Project     = "Serverless-Monitor"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "high-cpu-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "adric2001@gmail.com"
}

output "table_name" {
  value = aws_dynamodb_table.metrics_table.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}


resource "aws_iam_role" "lambda_role" {
  name = "serverless_monitor_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "serverless_monitor_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.metrics_table.arn
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "backend" {
  filename      = "lambda_function.zip"
  function_name = "ServerlessMonitorLogic"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.metrics_table.name
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }
}