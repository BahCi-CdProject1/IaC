terraform {
 required_providers {
   aws = {
     source = "hashicorp/aws"
   }
 }
 backend "s3" {
   region = "us-east-1"
   key    = "terraform.tfstate"
 }
}

provider "aws" {
  region  = "us-east-1"
  # profile = "<CHANGE THIS!>"
}

resource "aws_instance" "web_server" {
  ami           = "ami-06deb6bd572fb29e9"
  instance_type = "t2.micro"
  # user_data     = file("init.sh")
  tags = {
    Name = "web-server-terraform"
  }
}