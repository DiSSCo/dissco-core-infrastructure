terraform {
  backend "s3" {
    bucket = "doi-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-north-1"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}