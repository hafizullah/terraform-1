output "ipa_vpc_id" {
  value = "${aws_vpc.mgmt-us-west-2.id}"
}

output "ipa_security_group_id" {
  value = "${aws_security_group.opswest-ipa-sg.id}"
}

output "ipa_2a_subnet_id" {
  value = "${aws_subnet.us-west-2a-private-subnet.id}"
}

output "ipa_2b_subnet_id" {
  value = "${aws_subnet.us-west-2b-private-subnet.id}"
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
