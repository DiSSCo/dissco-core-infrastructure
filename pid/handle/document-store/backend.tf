terraform {
  backend "s3" {
    bucket = "dissco-terraform-state-backend"
    key    = "handle/document-store/terraform.tfstate"
    region = "eu-north-1"

    dynamodb_table = "terraform_state"
    encrypt        = true
  }
}