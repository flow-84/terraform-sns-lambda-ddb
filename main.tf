provider "aws" {
  region  = "eu-central-1"
  profile = "student"
}

# SNS Topic
resource "aws_sns_topic" "my_topic" {
  name = "my-topic"
}

# DynamoDB Table
resource "aws_dynamodb_table" "my_table" {
  name         = "my-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "lambda_function_payload.zip"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_dynamodb_policy
  ]
}

# SNS Subscription to Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.my_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.my_lambda.arn

  depends_on = [
    aws_lambda_function.my_lambda
  ]
}

# Lambda permission to allow SNS to trigger it
resource "aws_lambda_permission" "sns_trigger_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.my_topic.arn

  depends_on = [
    aws_sns_topic_subscription.lambda_subscription
  ]
}
