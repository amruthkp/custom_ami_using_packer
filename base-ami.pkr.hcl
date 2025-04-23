packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

data "amazon-ami" "example" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  region = "us-west-2"
}

source "amazon-ebs" "ssm-example" {
  ami_name             = "packer_AWS {{timestamp}}"
  instance_type        = "t2.micro"
  region               = "us-west-2"
  source_ami           = data.amazon-ami.example.id
  ssh_interface        = "session_manager"
  communicator         = "none"
  iam_instance_profile = "myinstanceprofile"
}

build {
  sources = ["source.amazon-ebs.ssm-example"]

  provisioner "shell" {
    inline = ["echo Provisioning with SSM..."]
  }
}
