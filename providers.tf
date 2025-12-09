terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" {
  #   # Recomendado para CI/CD: Guardar o estado num bucket S3 (crie o bucket manualmente na AWS Academy antes)
  #   # bucket = "nome-do-seu-bucket-terraform-state"
  #   # key    = "rds/terraform.tfstate"
  #   # region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

}