terraform {
  backend "s3" {
    bucket = "dissco-terraform-state-backend"
    key    = "test/s3/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}