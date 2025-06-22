resource "aws_s3_bucket" "doc_vault" {
    bucket = var.s3_bucket_name 
}

resource "aws_s3_bucket_website_configuration" "doc_vault_website" {
    bucket = aws_s3_bucket.doc_vault.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

resource "aws_s3_bucket_public_access_block" "doc_vault_public_access_block" {
    bucket  = aws_s3_bucket.doc_vault.id
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "doc_vault_policy" {
    bucket = aws_s3_bucket.doc_vault.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.doc_vault.arn}/*"
            }
        ]
    })
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/../frontend/public", "**")
  bucket = var.s3_bucket_name
  depends_on = [ aws_s3_bucket.doc_vault ]
  key    = each.value
  source = "${path.module}/../frontend/public/${each.value}"
  etag   = filemd5("${path.module}/../frontend/public/${each.value}")
  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
  }, split(".", each.value)[length(split(".", each.value)) - 1],
  "application/octet-stream")
}
