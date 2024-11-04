terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
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
  name = "ubuntu:latest"
}

resource "docker_container" "ubuntu_ssh_container" {
  count = var.num_containers

  name  = "ubuntu_ssh_${count.index}"
  image = docker_image.ubuntu.name

  ports {
    internal = 22
    external = 2200 + count.index
  }

  entrypoint = ["/bin/sh", "-c", "while true; do sleep 1000; done"]

  provisioner "local-exec" {
    command = <<-EOT
      docker exec ubuntu_ssh_${count.index} /bin/sh -c "
        apt-get update &&
        apt-get install -y openssh-server &&
        mkdir -p /root/.ssh &&
        echo '${local.ssh_public_key}' > /root/.ssh/authorized_keys &&
        chmod 600 /root/.ssh/authorized_keys &&
        service ssh start
      "
    EOT
  }
}

