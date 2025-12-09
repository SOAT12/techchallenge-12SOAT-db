output "rds_endpoint" {
  description = "O endpoint de conexão do RDS"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "A porta do banco de dados"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.postgres.db_name
}