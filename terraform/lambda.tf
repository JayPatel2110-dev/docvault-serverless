resource "aws_lambda_function" "doc_vault_lambda" {
  function_name = "DocVaultLambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.10"
  depends_on = [ aws_iam_role.lambda_exec ]
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")
  filename         = "${path.module}/../lambda/lambda_function.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME      = var.s3_bucket_name
      JWT_SECRET_KEY     = var.JWT_SECRET_KEY
    }
  }

  tags = {
    Project = "DocVault"
  }
  
}