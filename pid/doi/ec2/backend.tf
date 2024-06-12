terraform {
  backend "s3" {
    bucket = "doi-terraform-state-backend"
    key    = "doi/ec2/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}