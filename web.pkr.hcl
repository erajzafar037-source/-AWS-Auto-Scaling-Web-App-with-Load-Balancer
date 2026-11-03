packer {
  required_plugins {
    amazon = { version = ">= 1.3.0", source = "github.com/hashicorp/amazon" }
  }
}

variable "region" { default = "us-east-1" }
variable "app_version" { default = "dev" }

source "amazon-ebs" "web" {
  region        = var.region
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"
  ami_name      = "fastapi-web-${var.app_version}-{{timestamp}}"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  tags = { Name = "fastapi-web", Version = var.app_version, Project = "aws-autoscaling-webapp" }
}

build {
  sources = ["source.amazon-ebs.web"]

  provisioner "file" {
    source      = "../app"
    destination = "/tmp/app"
  }

  provisioner "file" {
    source      = "web.service"
    destination = "/tmp/web.service"
  }

  provisioner "shell" {
    inline = [
      "sudo dnf install -y python3.11 python3.11-pip amazon-cloudwatch-agent",
      "sudo mkdir -p /opt/app && sudo cp -r /tmp/app/* /opt/app/",
      "sudo python3.11 -m pip install -r /opt/app/requirements.txt",
      "echo APP_VERSION=${var.app_version} | sudo tee /etc/app.env",
      "sudo mv /tmp/web.service /etc/systemd/system/web.service",
      "sudo systemctl enable web.service"
    ]
  }
}
