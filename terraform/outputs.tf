output "s3_website_url" {
  description = "The URL of the S3 bucket hosting the static website."
  value       = "http://${aws_s3_bucket.doc_vault.bucket_regional_domain_name}"
}

output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.docvault_api.id}.execute-api.${var.region}.amazonaws.com/prod"
}