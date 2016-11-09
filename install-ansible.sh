#!/bin/bash -v
mkdir security
cd security
mkdir ipa
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
