# AWS access details

provider "aws" {
  shared_credentials_file = "${var.home_dir}/.aws/credentials"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

# Create Management VPC
resource "aws_vpc" "mgmt-us-west-2" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.vpc_name}"
  }
}

# Create Command Control Jump Box
resource "aws_instance" "cc-jumpbox" {
  ami = "${var.cc_jumpbox_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.opswest-mgmt-public-subnet-sg.id}"]
  subnet_id = "${aws_subnet.us-west-2a-public-subnet.id}"
  associate_public_ip_address = true
  source_dest_check = false
  tags {
     Name = "${var.environment}-cc-jumpbox"
  }
}
resource "aws_eip" "cc-jumpbox" {
  instance = "${aws_instance.cc-jumpbox.id}"
  vpc = true
}
# Create an internet gateway
resource "aws_internet_gateway" "ipa-opswest-igw" {
  vpc_id = "${aws_vpc.mgmt-us-west-2.id}"
  tags {
     Name = "${var.project}-igw"
  }
}
# Create NAT Gateways for public-subnet1 routing
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.us-west-2a-public-subnet.id}"
}
resource "aws_eip" "nat" {
  vpc = true
}
# Public Subnet1 in AZ1
resource "aws_subnet" "us-west-2a-public-subnet" {
  vpc_id                  = "${aws_vpc.mgmt-us-west-2.id}"
  availability_zone =  "${element(var.availability_zones, 0)}"
  cidr_block              = "${var.public_subnet1_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.vpc_name}-us-west-2a-public-subnet"
  }
}

resource "aws_route_table_association" "us-west-2a-public-subnet" {
  subnet_id      = "${aws_subnet.us-west-2a-public-subnet.id}"
  route_table_id = "${aws_route_table.us-west-2a-public-subnet.id}"
}

resource "aws_route_table" "us-west-2a-public-subnet" {
  vpc_id = "${aws_vpc.mgmt-us-west-2.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-opswest-igw.id}"
  }

  tags {
    Name = "${var.vpc_name}-us-west-2a-public-subnet"
  }
}

# Create NAT Gateways for public-subnet2 routing

resource "aws_nat_gateway" "nat-gw2" {
  allocation_id = "${aws_eip.nat-gw2.id}"
  subnet_id = "${aws_subnet.us-west-2b-public-subnet.id}"
}

resource "aws_eip" "nat-gw2" {
  vpc = true
}

# Public Subnet in AZ2
resource "aws_subnet" "us-west-2b-public-subnet" {
  vpc_id                  = "${aws_vpc.mgmt-us-west-2.id}"
  availability_zone = "${element(var.availability_zones, 1)}"
  cidr_block              = "${var.public_subnet2_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.vpc_name}-us-west-2b-public-subnet"
  }
}
resource "aws_route_table_association" "us-west-2b-public-subnet" {
  subnet_id      = "${aws_subnet.us-west-2b-public-subnet.id}"
  route_table_id = "${aws_route_table.us-west-2b-public-subnet.id}"
}
resource "aws_route_table" "us-west-2b-public-subnet" {
  vpc_id = "${aws_vpc.mgmt-us-west-2.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-opswest-igw.id}"
  }
  tags {
    Name = "${var.vpc_name}-us-west-2b-public-subnet"
  }
}
# Private Subnet1 in AZ1
resource "aws_subnet" "us-west-2a-private-subnet" {
  vpc_id                  = "${aws_vpc.mgmt-us-west-2.id}"
  availability_zone = "${element(var.availability_zones, 0)}"
  cidr_block              = "${var.private_subnet1_cidr_block}"
  tags {
    Name = "${var.vpc_name}-us-west-2a-private-subnet"
  }
}

resource "aws_route_table_association" "us-west-2a-private-subnet" {
  subnet_id      = "${aws_subnet.us-west-2a-private-subnet.id}"
  route_table_id = "${aws_route_table.us-west-2a-private-subnet.id}"
}

resource "aws_route_table" "us-west-2a-private-subnet" {
  vpc_id = "${aws_vpc.mgmt-us-west-2.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-opswest-igw.id}"
  }

  tags {
    Name = "${var.vpc_name}-us-west-2a-private-subnet"
  }
}


# Private Subnet2 in AZ2
resource "aws_subnet" "us-west-2b-private-subnet" {
  vpc_id                  = "${aws_vpc.mgmt-us-west-2.id}"
  availability_zone = "${element(var.availability_zones, 1)}"
  cidr_block              = "${var.private_subnet2_cidr_block}"
  tags {
    Name = "${var.vpc_name}-us-west-2b-private-subnet"
  }
}
resource "aws_route_table_association" "us-west-2b-private-subnet" {
  subnet_id      = "${aws_subnet.us-west-2b-private-subnet.id}"
  route_table_id = "${aws_route_table.us-west-2b-private-subnet.id}"
}
resource "aws_route_table" "us-west-2b-private-subnet" {
  vpc_id = "${aws_vpc.mgmt-us-west-2.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-opswest-igw.id}"
  }
  tags {
    Name = "${var.vpc_name}-us-west-2b-private-subnet"
  }
}
# Create security group for freeipa
resource "aws_security_group" "opswest-ipa-sg" {
  name        = "${var.environment}-ipa-sg"
  description = "Security group for FreeIPA"
  vpc_id      = "${aws_vpc.mgmt-us-west-2.id}"
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
}
resource "aws_security_group_rule" "SSH_access_from_CC_JumpBoxes" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_ELB" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-elb-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-elb-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_CC_JumpBoxes" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
}
resource "aws_security_group_rule" "HTTP_access_from_port_80" {
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "Port_88_inbound_access_from_self_sg" {
  type = "ingress" 
  from_port   = 88
  to_port     = 88
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "LDAP_access_from_self_sg" {
  type = "ingress"
  from_port   = 389
  to_port     = 389
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "Allow_HTTPS_access_from_self_sg" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_464_from_self_sg" {
  type = "ingress"
  from_port   = 464
  to_port     = 464
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_636_from_self_sg" {
  type = "ingress"
  from_port   = 636
  to_port     = 636
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "Allow_UDP_access_from_self_sg" {
  type = "ingress"
  from_port   = 123
  to_port     = 123
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
# Create security group for elb
resource "aws_security_group" "opswest-elb-sg" {
  name        = "opswest-elb-sg"
  description = "Security group for ELB"
  vpc_id      = "${aws_vpc.mgmt-us-west-2.id}"
  # Inbound internet access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "https_outbound_access_to_ipa" {
  type = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "icmp_outbound_access_to_ipa" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
resource "aws_security_group_rule" "ping_outbound_access_to_public_subnets" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-mgmt-public-subnet-sg.id}"
}
# Create security group for Public Subnet
resource "aws_security_group" "opswest-mgmt-public-subnet-sg" {
  name        = "opswest-mgmt-public-subnet-sg "
  description = "Security group for Public Subnets"
  vpc_id      = "${aws_vpc.mgmt-us-west-2.id}"
  # inbound ssh access from FYE DC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = "96.46.157.30/32" # to be replaced with FEYE DC CIDR Block
  }
}
resource "aws_security_group_rule" "ssh_outbound_access_to_ipa" {
  type = "egress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
  source_security_group_id = "${aws_security_group.opswest-ipa-sg.id}"
}
# Create instance
resource "aws_instance" "ipa-master" {
  ami = "${var.ipa_server_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.opswest-ipa-sg.id}"]
  subnet_id = "${aws_subnet.us-west-2a-private-subnet.id}"
  associate_public_ip_address = false

  tags {
     Name = "${var.project}-master"
  }
}

# Create instance
resource "aws_instance" "ipa-replica" {
  ami = "${var.ipa_server_ami}"
  availability_zone = "${element(var.availability_zones, 1)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.opswest-ipa-sg.id}"]
  subnet_id = "${aws_subnet.us-west-2b-private-subnet.id}"
  associate_public_ip_address = false
  tags {
     Name = "${var.project}-replica"
  }
}
# Create ELB
resource "aws_elb" "opswest-ipa-elb" {
  name = "${var.environment}-ipa-elb"
  subnets = ["${aws_subnet.us-west-2a-public-subnet.id}","${aws_subnet.us-west-2b-public-subnet.id}"]
  security_groups = ["${aws_security_group.opswest-elb-sg.id}"]
   
  listener {
	instance_port = 80
        instance_protocol = "http"
	lb_port = 80
	lb_protocol = "http"
  }
  health_check {
        healthy_threshold = 2
	unhealthy_threshold = 2
	timeout = 3
	target = "HTTP:80/"
	interval = 30
  }
  instances = ["${aws_instance.ipa-master.id}","${aws_instance.ipa-replica.id}"]
    
  tags = {
     Name = "${var.environment}-ipa-elb"
  }
}
