#=======================================
# SOC 龍蝦系統 — 資安服務設定
# GuardDuty + EventBridge + Lambda
#=======================================

#=======================================
# SNS Topic（Telegram 通知）
#=======================================
resource "aws_sns_topic" "security_alerts" {
  name = "SOC-Security-Alerts"

  tags = {
    Name        = "SOC-SNS-Topic"
    Environment = var.environment
  }
}

#=======================================
# IAM Role（Lambda 執行角色）
#=======================================
resource "aws_iam_role" "lambda_role" {
  name = "SOC-Lambda-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "SOC-Lambda-Role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_backup" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupFullAccess"
}

#=======================================
# Lambda Function（資安自動回應）
#=======================================
resource "aws_lambda_function" "security_response" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "SOC-Security-Response"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 300
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = "REPLACE_WITH_TELEGRAM_BOT_TOKEN"
      TELEGRAM_CHAT_ID   = "8741631019"
      SNS_TOPIC_ARN      = aws_sns_topic.security_alerts.arn
    }
  }

  tags = {
    Name        = "SOC-Lambda"
    Environment = var.environment
  }
}

#=======================================
# EventBridge Rule（監聽 GuardDuty）
#=======================================
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "SOC-GuardDuty-Findings"
  description = "Capture GuardDuty findings for SOC automation"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
  })

  tags = {
    Name        = "SOC-GuardDuty-Rule"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SOC-Lambda"
  arn       = aws_lambda_function.security_response.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_response.function_name
  principal     = "events.amazonaws.com"
  source_arn     = aws_cloudwatch_event_rule.guardduty_findings.arn
}

#=======================================
# SNS Subscription（Lambda → Telegram）
#=======================================
resource "aws_sns_topic_subscription" "lambda_to_sns" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.security_response.arn
}

#=======================================
# CloudWatch Log Group（Lambda 日誌）
#=======================================
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/SOC-Security-Response"
  retention_in_days = 7

  tags = {
    Name        = "SOC-Lambda-Logs"
    Environment = var.environment
  }
}

#=======================================
# Outputs
#=======================================
output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = aws_lambda_function.security_response.function_name
}

output "eventbridge_rule_name" {
  description = "EventBridge Rule Name"
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}