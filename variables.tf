variable "aws_creds_path"
 default = "/home/ec2-user/"
}

variable "project" {
  default = "ipa"
  }

variable "environment" {
  default = "opswest"
  }

variable "vpc_cidr_block" {
  default = "172.16.248.0/23"
  }

variable "private_subnet1_cidr_block" {
  default = "172.16.248.0/28"
  }

variable "private_subnet2_cidr_block" {
  default = "172.16.248.16/28"
  }

variable "public_subnet1_cidr_block" {
  default = "172.16.249.0/28"
  }

variable "public_subnet2_cidr_block" {
  default = "172.16.249.16/28"
  }

variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b"]
  }

variable "cc_jumpbox_ami" {
  default = "ami-746aba14"
  }

variable "ipa_server_ami" {
  default = "ami-d2c924b2"
  }

variable "instance_type" {
  default = "t2.micro"
  }

variable "key_name" {
  default = "freeipa-key"
  }

variable "aws_region" {
  default = "us-west-2"
  }

variable "vpc_name" {
  default = "ipa-vpc"
  }
