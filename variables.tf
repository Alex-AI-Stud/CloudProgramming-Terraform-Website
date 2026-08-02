variable "bucket_name" {
    description = "Name des S3-Buckets für die Webseite (muss global eindeutig sein)"
    type = string
    default = "naturewatch-website-2024-eu"
}

variable "aws_region" {
    description = "AWS Region für den S3-Bucketg (Ursprungsserver)"
    type = string
    default = "eu-central-1" //Frankfurt
}

variable "project_name" {
    description = "Projektname für alle AWS-Ressourcen (Tags)"
    type = string
    default = "naturewatch"
}

variable "environment" {
  description = "Umgebung (z.Bsp. production, testing,...)"
  type = string
  default = "production"
}
