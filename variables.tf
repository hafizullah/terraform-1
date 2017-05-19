variable "home_dir" {}

variable "aws_profile" {}

variable "project" {}

variable "environment" {}

variable "vpc_cidr_block" {}

variable "private_subnet1_cidr_block" {}

variable "private_subnet2_cidr_block" {}

variable "public_subnet1_cidr_block" {}

variable "public_subnet2_cidr_block" {}

variable "availability_zones" {
  type        = "list"
}

variable "ccjumpbox_ami" {}

variable "ipa_server_ami" {}

variable "ipa_openvpn_proxy_ami" {}

variable "instance_type" {}

variable "key_name" {}

variable "aws_region" {}

variable "vpc_name" {}

variable "feyedc_cidr_block" {}

variable "remote_vpc_cidr_block" {}

variable "private_key" {
  description = "private key to connect to hosts from the jumpbox"
}

variable "count" {
  default     = "1"
  description = "the number of instances"
}

variable "ssl_certificate" {}
