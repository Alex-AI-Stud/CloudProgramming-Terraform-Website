terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

// Hauptregion: Frankfurt (S3-Bucket Standort)
provider "aws" {
    region = var.aws_region  
}

// ---------------- Aktivieren bei Domainen-Einbindung ----------------
# // CloudFornt benötigt zwingend us-east-1 für ACM-Zertifikate
# // bei Anbindung einer Domaine (Route 53)
# provider "aws" {
#     alias = "us_east_1"
#     region = "us-east-1"  
# }
