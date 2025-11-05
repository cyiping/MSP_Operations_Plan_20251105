output "vpc_id" {
  value = aws_vpc.this.id
}

output "eks_cluster_name" {
  value = module.eks.cluster_id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
