# Terraform Module - Base - VPC

# usage

Enable by putting the following in your main.tf

```
module "vpc" {
     source = "github.mandiant.com/dprasad/ipa_module_mgmt_vpc"
     name = "ipa-vpc"
     aws_region = "us-west-2"
     key_name = "freeipa-key"
     vpc_cidr_block = "172.16.248.0/23"
     private_subnet1_cidr_block = "172.16.248.0/28"
     private_subnet2_cidr_block = "172.16.248.16/28"
     public_subnet1_cidr_block = "172.16.249.0/28"
     public_subnet2_cidr_block = "172.16.249.16/28"
     availability_zones = ["us-west-2a", "us-west-2b"]
     cc_jumpbox_ami = "ami-746aba14"
     instance_type = "t2.micro"
     enviornment = "opswest"
     project = "ipa"
 }
```
