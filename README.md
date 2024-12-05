# Labservers

This repository contains the files I use to create labservers for my students. I have been using _centos-stream-9-x64_ as template, and have done some successful attempts with Red Hat Enterprise Linux 9, but am not finished with RHEL yet.

You have to run Terraform to create the infrastructure (virtual machines) and terraform will create an Ansible inventory file for you. Then you run Ansible to configure the machines.

If you want $200 USD to start your journey with Digital Ocean, maybe to try my solution, you can use this link [digitalocean.com](https://tr.ee/84vg7U9mwm).

If you want to contact me for ideas or suggestions: jonas.bjork@gmail.com 

## Terraform

The terraform part will create the virtual machines on Digital Ocean for you. They will be reached at server-NUMBER.PROJECT_NAME.DOMAIN, example: server-14.datorkurs.skolan.se where server-14 is the created virtual machine, datorkurs is the project name and skolan.se is the domain name. These values is set in the terraform.tfvars file, use the terraform.tfvars.example file to populate your own configuration.

Terraform will create an inventory file for Ansible. Based on the template in `templates/ansible_inventory.tpl`. I am adding the virtual machine IP address in the inventory as DNS sometimes is slow to update. 

```sh
$ terraform plan
$ terraform apply
```

Wait a while and you got your virtual machines (droplets).

## Ansible

When you are running the Terraform job it will create an Ansible inventory file and save that file in the `ansible/`-folder. The inventory contains of all servers created, one on each row. I also use `ansible_host` in the file so we don't have to wait for DNS to update.

The Ansible part is one run and it is all in the `install.yaml` file. You need to change the username and password on lines 7 and 8. Default values are _labuser_ for the username to be created (the account your student will login with) and SET_YOUR_PASSWORD is the default password. Change it!

Ansible will:
- Set timezone to Europe/Stockholm.
- Upgrade all packages to the latest versions.
- Install man-pages, nano, podman, git-core and jq packages.
- Import EPEL-repository.
- Install fail2ban, as the servers are public to the internet. I have plans of placing them behind VPN later.
- Ansible will set the default editor to nano, as my students seem to have issues with vim.
- Creates the _labuser_ user account and make it part of wheel group (meaning it can sudo to root, if this is not wanted - remove the "groups: wheel" line). Then I make the account to force a password change on first login.
- SSH is configured so it allows password as authentication. The students does not have keys yet.
- And finally the firewall (firewalld) is configured.

That's it, just run the playbook and wait.

```sh
$ ansible-playbook install.yaml
```

If you need a `ansible.cfg` file, this is one example:

```
[defaults]
inventory = inventory
remote_user = root
private_key_file =  ~/.ssh/id_rsa
```

