# Terraform Module - Base - bastion

# usage

Enable by putting the following in your main.tf

```
module "bastion" {
  source = "git::https://v-usmi-e-github1.eng.fireeye.com/ops-infrastructure/terraform_module_base_bastion.git"
  vpc_id               = "${module.vpc.id}"
  subnet_id            = "${module.vpc.external_subnets}"
  key_name             = "${module.vpc.key_name}"
  cust_id              = "${module.vpc.cust_id}"
  product              = "${module.vpc.product}"
  designation          = "${module.vpc.designation}"
  environment          = "${module.vpc.environment}"
  mgmt                 = "${module.vpc.mgmt}"
  cidr                 = "${module.vpc.cidr}"
}
```

# optional

The module supports overriding the instance type and count.

```
ami_version       = "v1.0"       # defaults to *
ami_user          = "jkordish"   # defaults to build which is Jenkins
instance_type     = "t2.medium"
count             = "2"
target            = "production" # defines ingress ssh access
security_groups = "${module.consul.security_group}"
root_block_device = "30"
```

notes

The security_groups specifies additional security groups as its own bastion security will always be added by default and reference self.
