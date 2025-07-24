terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "us-east-1"
}

# Archive the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

# Attach Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda Function
resource "aws_lambda_function" "example" {
  function_name = "my_test_lambda"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 10

  vpc_config {
    subnet_ids         = [
      "subnet-06b890f36c1d8aa84",
      "subnet-0c512f1685f3cf34b"
    ]
    security_group_ids = ["sg-05e0b063a67841948"]
  }

  environment {
    variables = {
      LOG_LEVEL = "info"
    }
  }
}

# CloudWatch Log Group (Optional)
resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/my_test_lambda"
  retention_in_days = 14
}
