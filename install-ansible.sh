#!/bin/bash -v
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
sudo mkdir ~/security/
sudo mkdir ~/security/ipa
