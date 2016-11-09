#!/bin/bash -v
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
mkdir ~/security
mkdir ~/security/ipa
