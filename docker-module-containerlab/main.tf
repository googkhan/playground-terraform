# tofu file for ubuntu container with ssh access to host computer with public key
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

locals {
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
}

variable "num_containers" {
  default = 2
}

resource "docker_image" "ubuntu" {
  name         = "ubuntu:latest"
  keep_locally = true
}

resource "docker_container" "ubuntu_ssh_container" {
  count = var.num_containers
  name  = "ubuntu_ssh_${count.index}"
  image = docker_image.ubuntu.latest

  ports {
    internal = 22
    external = 2200 + count.index
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y openssh-server",
      "mkdir -p /root/.ssh/",
      "echo '${local.ssh_public_key}' >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "systemctl enable --now ssh.service"
    ]

    connection {
      type = "docker"
      user = "root"
    }
  }
}
