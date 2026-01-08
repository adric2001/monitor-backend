terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
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