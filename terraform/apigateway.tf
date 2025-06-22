resource "aws_apigatewayv2_api" "doc_vault_api" {
  name          = "doc-vault-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = ["*"] # Change to your actual frontend URL in production
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    expose_headers    = ["*"]
    max_age           = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.doc_vault_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.doc_vault_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "register_route" {
  api_id    = aws_apigatewayv2_api.doc_vault_api.id
  route_key = "POST /register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "login_route" {
  api_id    = aws_apigatewayv2_api.doc_vault_api.id
  route_key = "POST /login"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "list_files_route" {
  api_id    = aws_apigatewayv2_api.doc_vault_api.id
  route_key = "GET /list-files"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.doc_vault_api.id
  name        = "default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doc_vault_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.doc_vault_api.execution_arn}/*/*"
}
