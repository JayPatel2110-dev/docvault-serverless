variable "s3_bucket_name" {
  description = "The name of the S3 bucket to be created for document storage."
  type        = string
  default     = "static-doc-vault"
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table to be created for user data."
  type        = string
  default     = "doc_vault_users"
}

variable "JWT_SECRET_KEY" {
  description = "The secret key used for signing JWT tokens."
  type        = string
  sensitive   = true
}

variable "api_routes" {
  description = "List of route paths for the unified Lambda"
  type        = list(string)
  default     = ["/register", "/login", "/list-files", "/get-upload-url", "/delete-file"]
}

variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "ap-south-1"
}
