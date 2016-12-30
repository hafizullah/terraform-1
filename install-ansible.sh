#!/bin/bash -v
sudo -u ubuntu mkdir /home/ubuntu/security
sudo -u ubuntu mkdir /home/ubuntu/security/ipa
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update && sudo apt-get install ansible -y
sudo apt-get install yum
sudo -u ubuntu mkdir /home/ubuntu/security/inventory
sudo apt-get install python-pip -y
sudo apt-get install python-boto -y
