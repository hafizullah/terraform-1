#!/bin/bash -v
sudo apt-get update && sudo apt-get install ansible -y
mkdir sudo /etc/ansible/inventory
wget https://github.com/ddimri/ipa/blob/master/freeipa /etc/ansible/inventory
#git clone https://github.com/ddimri/ipa/:freeipa /etc/ansible/inventory
wget https://github.com/ddimri/ipa/blob/master/ec2-registration-ipa-master.yml ~/security/ipa
