#!/bin/bash -v
mkdir /home/ubuntu/security
mkdir /home/ubuntu/security/ipa
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
