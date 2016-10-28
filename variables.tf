variable "instance_type" {
  default     = "t2.medium"
  description = "Instance type, see a list at: https://aws.amazon.com/ec2/instance-types/"
}

variable "ami_version" {
  default     = "*"
  description = "the ami version - e.g. v1.0.0"
}

variable "ami_user" {
  default     = "build"
  description = "AMI user tag. Defaults to build which is Jenkins"
}

variable "count" {
  default     = "2"
  description = "the number of instances"
}

variable "root_block_device" {
  default     = "30"
  description = "size of root block device in GB"
}

variable "iam_instance_profile" {
  description = "Instance profile ARN to use in the launch configuration"
}

variable "security_groups" {
  description = "Comma separated list of security groups"
  default     = ""
  type        = "string"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "key_name" {
  description = "The SSH key pair, key name"
}

variable "private_key" {
  description = "private key to use to connect to hosts beyond the bastion"
}

variable "subnet_ids" {
  description = "A external subnet id"
  type        = "list"
}

variable "cust_id" {
  description = "Unique identifier for the VPC"
  type        = "string"
}

variable "product" {
  description = "The product to tag these resources with"
  type        = "string"
}

variable "designation" {
  description = "Designation for billing purposes"
  type        = "string"
}

variable "environment" {
  description = "Environment for billing purposes"
  type        = "string"
}

variable "mgmt" {
  description = "AWS account for billing purposes"
  type        = "string"
}

variable "target" {
  description = "either development or production."
  type        = "string"
  default     = "development"
}

variable "secure_ingress" {
  default = {
    development = "174.137.33.139/32,182.75.56.82/32,199.16.196.1/32,205.233.0.253/32,209.135.212.252/32,50.201.125.254/32,52.70.211.170/32,52.71.165.25/32,64.138.11.194/32,80.241.74.194/32,10.1.1.85/32,52.37.242.82/32"
    production  = "205.233.0.253/32,209.135.212.252/32,50.201.125.254/32,199.16.196.1/32"
  }
}
