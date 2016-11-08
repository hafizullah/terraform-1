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

variable "cc_jumpbox_ami" {}

variable "ipa_server_ami" {}

variable "instance_type" {}

variable "key_name" {}

variable "aws_region" {}

variable "vpc_name" {}

variable "feyedc_cidr_block" {}

variable "private_key" {
  description = "private key to connect to hosts from the jumpbox"
}
