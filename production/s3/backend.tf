terraform {
  backend "s3" {
    bucket = "dissco-terraform-state-backend"
    key    = "production/s3/terraform.tfstate"
    region = "eu-north-1"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}