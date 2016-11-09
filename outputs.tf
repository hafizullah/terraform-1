output "ipa_vpc_id" {
  value = "${module.vpc.mgmt-us-west-2.id}"
}

output "ipa_security_group_id" {
  value = "${module.vpc.opswest-ipa-sg.id}"
}

output "ipa_2a_subnet_id" {
  value = ["${module.vpc.us-west-2a-private-subnet.id}"]
}

output "ipa_2b_subnet_id" {
  value = ["${module.vpc.us-west-2b-private-subnet.id}"]
}

output "ipa_master_private_dns" {
  value = ["${module.vpc.ipa-master.private_dns}"]
}

output "ipa_master_private_ip" {
  value = ["${module.vpc.ipa-master.private_ip}"]
}

output "ipa_replica_private_dns" {
  value = ["${module.vpc.ipa-replica.private_dns}"]
}

output "ipa_replica_private_ip" {
  value = ["${module.vpc.ipa-replica.private_ip}"]
}
