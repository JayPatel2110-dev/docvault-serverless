output "s3_website_url" {
  description = "The URL of the S3 bucket hosting the static website."
  value       = "http://${aws_s3_bucket.doc_vault.bucket_regional_domain_name}"
}

output "api_base_url" {
  description = "Base URL of the API Gateway"
  value       = aws_apigatewayv2_api.doc_vault_api.api_endpoint
}