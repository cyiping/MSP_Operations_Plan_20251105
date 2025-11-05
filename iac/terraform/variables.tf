variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "state_bucket" {
  description = "S3 bucket for terraform state"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "meraki-msp"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "msp-eks"
}

variable "db_password" {
  description = "Postgres DB password. For PoC you can set a simple value, but for production use Secrets Manager or Vault and do NOT commit real secrets to Git."
  type        = string
  default     = "change_me"
  sensitive   = true
}

variable "deploy_to_aws" {
  description = "If true, you intend to deploy resources to AWS. This repo defaults to local-only so no AWS calls are made automatically."
  type        = bool
  default     = false
}
