packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "ssm-example" {
  region               = var.region
  instance_type        = "t2.micro"
  ssh_username         = "ubuntu"
  ssh_interface        = "session_manager"
  communicator         = "none"
  ami_name             = "packer-aws-ssm-ami-{{timestamp}}"
  iam_instance_profile = "myinstanceprofile"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  tags = {
    "Name"        = "SSM-Docker-Base-AMI"
    "Environment" = "Dev"
    "CreatedBy"   = "GitHubActions"
  }
}

build {
  sources = ["source.amazon-ebs.ssm-example"]

  provisioner "shell" {
    inline = [
      "echo 'Provisioning using SSM...'",
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx && sudo systemctl start nginx",
      "echo 'SSM-based AMI ready.'"
    ]
  }
}
