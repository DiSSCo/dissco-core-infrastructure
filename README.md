# dissco-core-infrastructure
Contains files for deploying and managing the core infrastructure.
We use [terraform](https://www.terraform.io/) for the deployment of our infrastructure.
These files describe how the infrastructure needs to be deployed on AWS, our cloud provider.

For each environment there is a folder with the Terraform files.
In the terraform-state-storage are the files with which the initial state storage resources were created.

## Deployment
Terraform should be run locally.
To synchronise follow these steps:
- Pull the latest version from the repository
- Move to the correct environment folder (example `cd acceptance`)
- Run `terraform init` this will download all required files and version
- Run `terraform plan` to see what changes terraform proposes
- Run `terraform apply` to start apply the changes
  - `yes` to approve the changes and run terraform

This should successfully update the infrastructure.

## Be aware
Be aware that the master password for the Document store (`document-store`) needs to be set manually.
It is secret, so we cannot push it to the GitHub repository.
For existing environments this secret is managed in the AWS Secret Store.

Be aware that the route table needs an update after the peering.
This is still a manual action and needs to be automated with Terraform. 