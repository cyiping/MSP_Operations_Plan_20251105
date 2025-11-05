/*
簡單示範使用 terraform-aws-modules/eks/aws module 的參考配置
實際上線請閱讀模組文件並按需調整 node group 與 IAM
*/

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  manage_aws_auth = true

  node_groups = {
    default = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}
