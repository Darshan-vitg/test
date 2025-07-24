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
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

# ─── Existing EC2 Instance ─────────────────────────────────────────────
data "aws_instance" "existing_ec2" {
  instance_id = "i-09d300c01c249"
}

# ─── Reuse existing IAM Role ───────────────────────────────────────────
data "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
}

# ─── Archive Lambda Function ───────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/slack-daily-samgov-lambda"
  output_path = "${path.module}/slack-daily-samgov-lambda.zip"
}

# ─── Archive Lambda Layer (requests) ───────────────────────────────────
resource "aws_lambda_layer_version" "requests_layer" {
  filename           = "${path.module}/requests-layer.zip"
  layer_name         = "requests-lib"
  compatible_runtimes = ["python3.9"]
  source_code_hash   = filebase64sha256("${path.module}/requests-layer.zip")
}

# ─── Lambda Function ───────────────────────────────────────────────────
resource "aws_lambda_function" "slack_daily_samgov_lambda" {
  function_name    = "slack-daily-samgov-lambda"
  handler          = "slack-daily-samgov-lambda.lambda_handler"
  runtime          = "python3.9"
  role             = data.aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  layers           = [aws_lambda_layer_version.requests_layer.arn]
  timeout          = 50
}

# ─── CloudWatch Event Rule (Every Day 8AM EST) ─────────────────────────
resource "aws_cloudwatch_event_rule" "daily_8Am_EST" {
  name                = "samgov-lambda-scheduler"
  schedule_expression = "cron(0 13 * * ? *)" # 8AM EST
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_8Am_EST.name
  target_id = "samgov-scheduled-run"
  arn       = aws_lambda_function.slack_daily_samgov_lambda.arn
}

# ─── Permissions to Allow EventBridge to Trigger Lambda ────────────────
resource "aws_lambda_permission" "allow_eventbridge_to_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_daily_samgov_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_8Am_EST.arn
}
