# Terraform Module - Base - VPC

# usage

Enable by putting the following in your main.tf

```
module "vpc" {
  source = "git::https://github.com/ddimri/terraform.git"
  home_dir = "/home/deepak_prasad"
  aws_profile = "freeipa-india0"
  project =  "ipa"
  environment = "opswest"
  vpc_cidr_block = "10.88.0.0/24"
  remote_vpc_cidr_block = "10.88.1.0/24"
  private_subnet1_cidr_block = "10.88.0.32/28"
  private_subnet2_cidr_block= "10.88.0.48/28"
  public_subnet1_cidr_block = "10.88.0.1/28"
  public_subnet2_cidr_block = "10.88.0.16/28"
  availability_zones = ["us-west-2a", "us-west-2b"]
  ccjumpbox_ami = "ami-01f05461"
  ipa_server_ami = "ami-d2c924b2"
  ipa_openvpn_proxy_ami = "ami-01f05461"
  instance_type = "t2.micro"
  key_name = "freeipa-key"
  aws_region = "us-west-2"
  vpc_name = "ipa-mgmt-vpc"
  feyedc_cidr_block = "96.46.157.30/32"   # to be replaced with FEYE DC CIDR Block
  private_key = "~/.ssh/freeipa-key.pem"
  ssl_certificate = "arn:aws:iam::157065524616:server-certificate/feyemetrics"
}

```
