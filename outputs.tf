output "ipa_vpc_id" {
  value = "${aws_vpc.ipa-mgmt-vpc.id}"
}

output "ipa_security_group_id" {
  value = "${aws_security_group.ipa-server-sg.id}"
}

output "ipa_2a_subnet_id" {
  value = "${aws_subnet.private-subnet1.id}"
}

output "ipa_2b_subnet_id" {
  value = "${aws_subnet.private-subnet2.id}"
}

output "ipa_master_1_private_dns" {
  value = "${aws_instance.ipa-master-1.private_dns}"
}

output "ipa_master_1_private_ip" {
  value = "${aws_instance.ipa-master-1.private_ip}"
}

output "ipa_master_2_private_dns" {
  value = "${aws_instance.ipa-master-2.private_dns}"
}

output "ipa_master_2_private_ip" {
  value = "${aws_instance.ipa-master-2.private_ip}"
}

output "ipa_openvpn_proxy_1_private_ip" {
  value = "${aws_instance.ipa-openvpn-proxy-1.private_ip}"
}

output "ipa_openvpn_proxy_2_private_ip" {
  value = "${aws_instance.ipa-openvpn-proxy-2.private_ip}"
}
