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
  default = "us-west-2"
}

source "amazon-ebs" "ubuntu" {
  region                      = var.region
  instance_type               = "t2.micro"
  ssh_username                = "ubuntu"
  ssh_timeout                 = "10m"
  ssh_handshake_attempts     = 60
  communicator                = "ssh"
  ami_name                    = "custom-ubuntu-docker-ssm-ami-{{timestamp}}"
  ami_description             = "Ubuntu 22.04 AMI with Docker, AWS SSM Agent, and NGINX"
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  tags = {
    "Name"        = "Docker-SSM-Base-AMI"
    "BaseImage"   = "Ubuntu"
    "Environment" = "Dev"
    "CreatedBy"   = "GitHubActions"
  }
}

source "amazon-ebs" "ssm-example" {
  ami_name             = "packer_AWS {{timestamp}}"
  instance_type        = "t2.micro"
  region               = "us-east-1"
  source_ami           = "ami-04181fdd41a180f25" # Replace with a valid AMI ID
  ssh_username         = "ubuntu"
  ssh_interface        = "session_manager"
  communicator         = "ssh"
  ssh_port             = 22
  iam_instance_profile = "myinstanceprofile" # Ensure this exists in AWS
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "echo 'Updating system packages...'",
      "sudo apt-get update && sudo apt-get upgrade -y",

      "echo 'Installing Docker...'",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",

      "echo 'Installing AWS SSM Agent...'",
      "curl -o ssm-agent.deb https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb",
      "sudo dpkg -i ssm-agent.deb",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",

      "echo 'Installing NGINX...'",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",

      "echo 'Base AMI provisioning complete!'"
    ]
  }
}

build {
  sources = ["source.amazon-ebs.ssm-example"]

  provisioner "shell" {
    inline = ["echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'"]
  }
}
