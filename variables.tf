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

variable "user_data" {
    description = "user data for setting up the ec2 instance"
}

variable "ami_version" {
  default     = "*"
  description = "the ami version - e.g. v1.0.0"
}

variable "root_block_device" {
  default     = "30"
  description = "size of root block device in GB"
}
