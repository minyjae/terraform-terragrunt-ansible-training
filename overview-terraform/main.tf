terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # หมายเลข Account ของ Canonical (บริษัทผู้สร้าง Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2-terraform" {
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-ec2-testing"
  }
}