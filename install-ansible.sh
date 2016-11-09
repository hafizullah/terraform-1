#!/bin/bash -v
mkdir $HOME/security
mkdir $HOME/security/ipa
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
