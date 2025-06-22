resource "aws_api_gateway_rest_api" "docvault_api" {
  name        = "docvault-api"
  description = "API Gateway for DocVault Lambda"
}

resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.docvault_api.id
  parent_id   = aws_api_gateway_rest_api.docvault_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.docvault_api.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.docvault_api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.docvault_lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doc_vault_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.docvault_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_stage" "docvault_stage" {
  rest_api_id = aws_api_gateway_rest_api.docvault_api.id
  stage_name  = "prod"
  deployment_id = aws_api_gateway_deployment.docvault_deployment.id
}

resource "aws_api_gateway_deployment" "docvault_deployment" {
  depends_on = [aws_api_gateway_integration.proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.docvault_api.id
}
