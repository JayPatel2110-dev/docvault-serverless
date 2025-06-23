resource "aws_lambda_function" "doc_vault_lambda" {
  function_name = "docvault-handler"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "${path.module}/../lambda_function.zip"
  role          = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
      USERS_TABLE = var.dynamodb_table_name
      BUCKET_NAME = var.s3_bucket_name
      JWT_SECRET  = var.JWT_SECRET_KEY
    }
  }
}
