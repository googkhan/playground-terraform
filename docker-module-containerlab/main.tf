# tofu file for ubuntu container with ssh access to host computer with public key

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

locals {
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
}

variable "num_containers" {
  default = 2
}

resource "docker_image" "ubuntu_ssh" {
  name         = "ubuntu:latest"
  keep_locally = true
}

resource "docker_image" "ubuntu_container" {
  count = var.num_containers
  name  = "ubuntu_ssh_${count.index}"
  image = docker_image.ubuntu_ssh.latest

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
