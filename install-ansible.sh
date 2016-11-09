#!/bin/bash -v
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
home_dir= $HOME
cd "$home_dir"
mkdir security
mkdir "$home_dir"/security/ipa
