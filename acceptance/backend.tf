terraform {
  backend "s3" {
    bucket         = "dissco-terraform-state-backend"
    dynamodb_table = "terraform_state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}