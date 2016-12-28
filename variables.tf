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
  type    = "list"
  default = ["us-west-2a", "us-west-2b"]
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
  default = "~/.ssh/freeipa-key.pem"
  description = "private key to connect to hosts from the jumpbox"
}

variable "count" {
  default     = "1"
  description = "the number of instances"
}

variable "root_block_device" {
  default     = "30"
  description = "size of root block device in GB"
}

variable "ssl_certificate" {}
