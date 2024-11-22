terraform {
  backend "s3" {
    bucket = "dissco-terraform-state-backend"
    key    = "production/k8s/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}