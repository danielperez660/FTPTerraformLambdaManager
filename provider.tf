terraform {
  backend "s3" {
    bucket = "ftp-tf"
    key    = "tfstate"
    region  = "eu-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  profile = "terraform"
}