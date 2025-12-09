# --- 1. Rede (VPC e Subnets) ---
# Cria uma VPC simples para o projeto
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-techchallenge-db"
  }
}

# Cria 2 Subnets em zonas diferentes (Exigência do RDS para Subnet Group)
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "subnet-db-a" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "subnet-db-b" }
}

# Grupo de Subnets para o RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "techchallenge-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Gateway de Internet (para permitir que o Terraform acesse a VPC se necessário, e para atualizações)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt.id
}

# --- 2. Security Group (Firewall) ---
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "PostgreSQL from anywhere (Restringir em Prod!)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. Instância RDS (PostgreSQL) ---
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  db_name              = var.db_name
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
  publicly_accessible  = true

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Project = "TechChallenge-Fase3"
  }
}

# --- 4. Armazenamento do Estado (S3) ---
# Cria um bucket para guardar o estado do Terraform
resource "aws_s3_bucket" "terraform_state" {
  # MUDE O NOME ABAIXO PARA ALGO ÚNICO NO MUNDO
  bucket = "techchallenge-fase3-terraform-state-seunome"

  force_destroy = true # Permite apagar o bucket mesmo com arquivos (útil para Academy)

  tags = {
    Name = "Terraform State Bucket"
  }
}

# Habilita versionamento (segurança para não perder o arquivo de estado)
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}