terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "<CHANGE THIS>"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0dfcb1ef8550277af"
  instance_type = "t2.micro"
  user_data     = file("init.sh")

  tags = {
    Name = "Jenkins-server"
  }
}