#!/bin/bash
sudo apt-get update && sudo apt-get install ansible -y
sudo mkdir /etc/ansible/inventory
cd $HOME
mkdir security
mkdir $HOME/security/ipa
