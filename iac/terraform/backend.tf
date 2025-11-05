/*
 By default this project uses a local backend so you can run Terraform
 locally without needing any AWS resources or credentials.

 If you want to collaborate and store the state remotely, uncomment the
 S3 backend below and set `var.state_bucket` to an existing S3 bucket.
 Make sure to create a DynamoDB table for state locking in team environments.

 NOTE: Keeping the local backend avoids any automatic connection to AWS
 when inspecting the files. Terraform will only attempt to contact AWS
 when you run `terraform init` / `terraform apply` in an environment that
 has AWS credentials configured.
*/

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

/* Example S3 backend (commented). To enable, replace the local backend
   above with this block and provide a valid `state_bucket` value.

terraform {
  backend "s3" {
    bucket = var.state_bucket
    key    = "terraform.tfstate"
    region = var.aws_region
    encrypt = true
  }
}
*/
