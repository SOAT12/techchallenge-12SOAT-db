variable "aws_region" {
  description = "Região da AWS"
  default     = "us-east-1" # Região padrão da Academy
}

variable "db_username" {
  description = "Usuário master do banco"
  default     = "postgres"
}

variable "db_password" {
  description = "Senha master do banco"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nome do banco de dados inicial"
  default     = "techchallenge"
}