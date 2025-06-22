resource "aws_iam_role" "lambda_exec" {
    name = "lambda_docvault_role"
    
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
}

resource "aws_iam_role_policy" "lambda_s3_dynamo_access" {
  name = "lambda-docvault-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["logs:*"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["dynamodb:GetItem", "dynamodb:PutItem"],
        Resource = "arn:aws:dynamodb:*:*:table/DocVaultUsers"
      },
      {
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::docvault-app"
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::docvault-app/users/*"
      }
    ]
  })
}
