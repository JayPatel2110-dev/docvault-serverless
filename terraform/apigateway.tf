resource "aws_apigatewayv2_api" "doc_vault_api" {
  name          = "doc-vault-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "OPTIONS","DELETE"]
    allow_headers     = ["Content-Type", "Authorization"]
    expose_headers    = ["*"]
    max_age           = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.doc_vault_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.doc_vault_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_routes" {
  for_each = {
    for route in var.api_routes : "${route}_method" =>
    {
      route_key = route == "/delete-file" ? "DELETE /delete-file" :(
                  route == "/list-files" ? "GET /list-files" :
                  "POST ${route}")
    }
  }
  api_id    = aws_apigatewayv2_api.doc_vault_api.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.doc_vault_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doc_vault_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.doc_vault_api.execution_arn}/*/*"
}
