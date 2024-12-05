terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "number_servers" {}
variable "do_token" {}
variable "school" {}
variable "ssh_private_key" {}
variable "ssh_public_key" {}
variable "project_name" {}
variable "domain" {}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "ssh-key" {
  name       = "Labserver public ssh key"
  public_key = file(var.ssh_public_key)
}

resource "digitalocean_project" "do-project" {
  name = var.project_name
  description = ""
  purpose = "Class project / Educational purposes"
  environment = "Development"
}

resource "digitalocean_droplet" "do-droplet" {
  count = var.number_servers
  image = "centos-stream-9-x64"
  name = "server-${format("%02d", count.index+1)}"
  region = "ams3"
  size = "s-1vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.ssh-key.fingerprint]
  tags = [ var.school, var.project_name ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.ssh_private_key)
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "#dnf upgrade -y"
    ]
  }
}

resource "digitalocean_project_resources" "do-project-resources" {
  project = digitalocean_project.do-project.id
  count = var.number_servers
  resources = [
    digitalocean_droplet.do-droplet[count.index].urn
  ]
}

resource "digitalocean_record" "do-record-a" {
  count = var.number_servers
  domain = var.domain
  type = "A"
  name = "${element(digitalocean_droplet.do-droplet.*.name, count.index)}.${var.project_name}"
  value = "${element(digitalocean_droplet.do-droplet.*.ipv4_address, count.index)}"
}

resource "local_file" "inventory" {
  content = templatefile (
    "templates/ansible_inventory.tpl",
    {
      droplet_name = digitalocean_droplet.do-droplet.*.name
      droplet_ip = digitalocean_droplet.do-droplet.*.ipv4_address
      project_name = var.project_name
      domain = var.domain
    }
  )
  filename = "ansible/inventory"
}
