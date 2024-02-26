terraform {
  backend "s3" {
    bucket = "doip-terraform-state-backend"
    key    = "doip/vpc/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}