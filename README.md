# 📦 DocVault - Secure Document Vault

DocVault is a simple web-based document management system built using AWS (S3, Lambda, API Gateway, DynamoDB) and deployed via GitLab CI/CD using Terraform.

---

## 🔧 Features
- User registration and login with JWT authentication
- Secure document uploads to S3 (presigned URLs)
- Document listing with download & delete options
- Responsive frontend hosted on S3 static website
- Fully serverless architecture

---

## 📂 Project Structure
```
.
├── frontend/
│   └── public/
│       ├── index.html
│       ├── register.html
│       ├── dashboard.html
│       └── style.css
├── lambda/
│   ├── index.js
│   └── package.json
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── .gitlab-ci.yml
└── README.md
```

---

## 🚀 Deployment (via GitLab CI/CD)

Ensure you set the following GitLab CI/CD variables:

### Required GitLab Variables:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `TF_VAR_s3_bucket_name` (e.g., `static-doc-vault`)
- `TF_VAR_dynamodb_table_name` (e.g., `doc_vault_users`)
- `TF_VAR_JWT_SECRET_KEY` (e.g., `your-very-secure-jwt-key`)
- `TF_VAR_api_routes` (e.g., `["/register", "/login", "/list-files", "/get-upload-url", "/delete-file"]`)
- `TF_VAR_region` (e.g., `ap-south-1`)

These GitLab variables are passed to Terraform and override the defaults defined in `variables.tf`.

### `.gitlab-ci.yml` Pipeline Overview:
1. **build_lambda**: Zips your Node.js Lambda function
2. **validate**: Runs `terraform validate`
3. **plan**: Executes `terraform plan` with variables
4. **apply**: Applies infrastructure, replaces frontend API URLs, and uploads HTML to S3

---

## 🌐 Setting Up Terraform Backend (`terraform/backend.tf`)
Create an S3 bucket and DynamoDB table manually or via Terraform to store the Terraform state.

```hcl
terraform {
  backend "s3" {
    bucket         = "your-tf-state-bucket"
    key            = "docvault/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### Setup Backend:
```bash
aws s3api create-bucket --bucket your-tf-state-bucket --region ap-south-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## ✅ TODO / Future Work
- Forgot password via email/OTP
- Multi-user file sharing
- File preview enhancements
- CI enhancements and automated testing

---

## 📝 License
MIT License

---

## 👨‍💻 Author
Built by **Jay Patel**