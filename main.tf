terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "4.6.0"
      }
  }
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

