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
  name       = "techchallenge-db-subnet-group-v2"
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
  engine_version       = "17"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
  final_snapshot_identifier = "ignore"
  publicly_accessible  = true

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Project = "TechChallenge-Fase3"
  }
}

# --- 4. Secrets Manager (Gerenciamento de Senhas) ---

# Cria o container do segredo com NOME FIXO
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "techchallenge-db-credentials"

  recovery_window_in_days = 0

  tags = {
    Name        = "Credenciais Banco TechChallenge"
    Environment = "Production"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_val" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username            = var.db_username
    password            = var.db_password
    engine              = "postgres"
    host                = aws_db_instance.postgres.address
    port                = aws_db_instance.postgres.port
    dbname              = aws_db_instance.postgres.db_name
    dbInstanceIdentifier = aws_db_instance.postgres.identifier

    # URL JDBC completa para facilitar a vida do desenvolvedor Java
    jdbc_url            = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  })
}