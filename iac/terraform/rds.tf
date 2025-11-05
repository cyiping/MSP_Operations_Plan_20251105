resource "aws_db_subnet_group" "default" {
  name       = "${var.project_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_prefix}-db"
  engine     = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  name = "mspdb"
  username = "mspadmin"
  # Use the variable `db_password`. For production, do NOT put secrets in Git.
  # Prefer using Secrets Manager and injecting the secret at deploy time.
  password = var.db_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible = false
  tags = { Name = "${var.project_prefix}-rds" }
}
