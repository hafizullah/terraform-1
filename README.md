# Terraform Module - Base - VPC

# usage

Enable by putting the following in your main.tf

```
module "vpc" {
  source = "git::https://github.eng.fireeye.com/deepak-prasad/terraform_mgmt_vpc.git"
  home_dir = "/home/deepak_prasad"
  aws_profile = "freeipa-india0"
  project =  "ipa"
  environment = "opswest"
  vpc_cidr_block= "172.16.248.0/23"
  private_subnet1_cidr_block = "172.16.248.0/28"
  private_subnet2_cidr_block= "172.16.248.16/28"
  public_subnet1_cidr_block = "172.16.249.0/28"
  public_subnet2_cidr_block = "172.16.249.16/28"
  availability_zones = ["us-west-2a", "us-west-2b"]
  ccjumpbox_ami = "ami-746aba14"
  ipa_server_ami = "ami-d2c924b2"
  instance_type = "t2.micro"
  key_name = "freeipa-key"
  aws_region = "us-west-2"
  vpc_name = "ipa-vpc"
  feyedc_cidr_block = "96.46.157.30/32"   # to be replaced with FEYE DC CIDR Block
  private_key = "~/.ssh/freeipa-key.pem"
}

```
