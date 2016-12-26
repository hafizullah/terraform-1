# AWS access details

provider "aws" {
  shared_credentials_file = "${var.home_dir}/.aws/credentials"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

# Create Management VPC
resource "aws_vpc" "ipa-mgmt-vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

# Create security group for Public Subnet
resource "aws_security_group" "ipa-mgmt-public-subnet-sg" {
  name        = "ipa-${var.environment}-mgmt-public-subnet-sg "
  description = "Security group for Public Subnets"
  vpc_id      = "${aws_vpc.ipa-mgmt-vpc.id}"
  # inbound ssh access from FYE DC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = ["${var.feyedc_cidr_block}"] # to be replaced with FEYE DC CIDR Block
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
}
resource "aws_security_group_rule" "ssh_outbound_access_to_ipa" {
  type = "egress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}

resource "aws_security_group_rule" "https_outbound" {
  type = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}

# Create Command Control Jump Box
resource "aws_instance" "ccjumpbox" {
  ami = "${var.ccjumpbox_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ipa-mgmt-public-subnet-sg.id}"]
  subnet_id = "${aws_subnet.public-subnet1.id}"
  associate_public_ip_address = true
  source_dest_check = false
  # Deploy ansible on the jump box	
  user_data = "${file("install-ansible.sh")}"
  count     = "${var.count}"
  lifecycle {
     ignore_changes = ["ami", "user_data"]
  }

  tags {
     Name = "ipa-${var.environment}-ccjumpbox"
  }
  
  provisioner "local-exec" {
  command = "./terraform output -state=terraform.tfstate -module=vpc > tf_file"
  }
}
	
resource "aws_eip" "ccjumpbox-ip" {
  instance = "${aws_instance.ccjumpbox.id}"
  vpc = true
  connection {
     host = "${aws_eip.ccjumpbox-ip.public_ip}"
     user = "ubuntu"
     timeout = "30s"
     private_key = "${file(var.private_key)}"
     agent = false
  }
  
  provisioner "file" {
    source      = "${var.private_key}"
    destination = "~/.ssh/${var.key_name}"
  }
    # tf_file contains the variable outputs from the module
  provisioner "file" {
    source      = "./tf_file"
    destination = "~/security/ipa/tf_file"
  }
  
    # copying vanila freeipa hosts inventory file to jump server
  provisioner "file" {
    source      = "./freeipa"
    destination = "~/security/inventory/freeipa"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0400 ~/.ssh/${var.key_name}",
    ]
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "ipa-vpc-igw" {
  vpc_id = "${aws_vpc.ipa-mgmt-vpc.id}"
  tags {
     Name = "ipa-${var.project}-igw"
  }
}
# Create NAT Gateways for public-subnet1 routing
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public-subnet1.id}"
}
resource "aws_eip" "nat" {
  vpc = true
}
# Public Subnet1 in AZ1
resource "aws_subnet" "public-subnet1" {
  vpc_id                  = "${aws_vpc.ipa-mgmt-vpc.id}"
  availability_zone =  "${element(var.availability_zones, 0)}"
  cidr_block              = "${var.public_subnet1_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 0)}-public-subnet"
  }
}

resource "aws_route_table_association" "public-subnet1" {
  subnet_id      = "${aws_subnet.public-subnet1.id}"
  route_table_id = "${aws_route_table.public-subnet1.id}"
}

resource "aws_route_table" "public-subnet1" {
  vpc_id = "${aws_vpc.ipa-mgmt-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-vpc-igw.id}"
  }

  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 0)}-public-subnet"
  }
}

# Create NAT Gateways for public-subnet2 routing

resource "aws_nat_gateway" "nat-gw2" {
  allocation_id = "${aws_eip.nat-gw2.id}"
  subnet_id = "${aws_subnet.public-subnet2.id}"
}

resource "aws_eip" "nat-gw2" {
  vpc = true
}

# Public Subnet in AZ2
resource "aws_subnet" "public-subnet2" {
  vpc_id                  = "${aws_vpc.ipa-mgmt-vpc.id}"
  availability_zone = "${element(var.availability_zones, 1)}"
  cidr_block              = "${var.public_subnet2_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-public-subnet"
  }
}
resource "aws_route_table_association" "public-subnet2" {
  subnet_id      = "${aws_subnet.public-subnet2.id}"
  route_table_id = "${aws_route_table.public-subnet2.id}"
}
resource "aws_route_table" "public-subnet2" {
  vpc_id = "${aws_vpc.ipa-mgmt-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ipa-vpc-igw.id}"
  }
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-public-subnet"
  }
}
# Private Subnet1 in AZ1
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = "${aws_vpc.ipa-mgmt-vpc.id}"
  availability_zone = "${element(var.availability_zones, 0)}"
  cidr_block              = "${var.private_subnet1_cidr_block}"
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 0)}-private-subnet"
  }
}

resource "aws_route_table_association" "private-subnet1" {
  subnet_id      = "${aws_subnet.private-subnet1.id}"
  route_table_id = "${aws_route_table.private-subnet1.id}"
}

resource "aws_route_table" "private-subnet1" {
  vpc_id = "${aws_vpc.ipa-mgmt-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }

  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 0)}-private-subnet"
  }
}


# Private Subnet2 in AZ2
resource "aws_subnet" "private-subnet2" {
  vpc_id                  = "${aws_vpc.ipa-mgmt-vpc.id}"
  availability_zone = "${element(var.availability_zones, 1)}"
  cidr_block              = "${var.private_subnet2_cidr_block}"
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-private-subnet"
  }
}
resource "aws_route_table_association" "private-subnet2" {
  subnet_id      = "${aws_subnet.private-subnet2.id}"
  route_table_id = "${aws_route_table.private-subnet2.id}"
}
resource "aws_route_table" "private-subnet2" {
  vpc_id = "${aws_vpc.ipa-mgmt-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw2.id}"
  }
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-private-subnet"
  }
}
# Create security group for freeipa
resource "aws_security_group" "ipa-server-sg" {
  name        = "ipa-${var.environment}-ipasrv-sg"
  description = "Security group for FreeIPA"
  vpc_id      = "${aws_vpc.ipa-mgmt-vpc.id}"
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
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-mgmt-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "SSH_access_from_self" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_ELB" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-elb-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_CC_JumpBoxes" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-mgmt-public-subnet-sg.id}"
}
resource "aws_security_group_rule" "HTTP_access_from_port_80" {
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "Port_88_inbound_access_from_self_sg" {
  type = "ingress" 
  from_port   = 88
  to_port     = 88
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "LDAP_access_from_self_sg" {
  type = "ingress"
  from_port   = 389
  to_port     = 389
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_HTTPS_access_from_self_sg" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_464_from_self_sg" {
  type = "ingress"
  from_port   = 464
  to_port     = 464
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_636_from_self_sg" {
  type = "ingress"
  from_port   = 636
  to_port     = 636
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_UDP_access_from_self_sg" {
  type = "ingress"
  from_port   = 123
  to_port     = 123
  protocol    = "tcp"
  security_group_id = "${aws_security_group.ipa-server-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
# Create security group for elb
resource "aws_security_group" "ipa-elb-sg" {
  name        = "ipa-${var.environment}-elb-sg"
  description = "Security group for ELB"
  vpc_id      = "${aws_vpc.ipa-mgmt-vpc.id}"
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
  security_group_id = "${aws_security_group.ipa-elb-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "icmp_outbound_access_to_ipa" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.ipa-elb-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-server-sg.id}"
}
resource "aws_security_group_rule" "ping_outbound_access_to_public_subnets" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.ipa-elb-sg.id}"
  source_security_group_id = "${aws_security_group.ipa-mgmt-public-subnet-sg.id}"
}

# Create instance
resource "aws_instance" "ipa-master-1" {
  ami = "${var.ipa_server_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ipa-server-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet1.id}"
  associate_public_ip_address = false

  tags {
     Name = "${var.project}-${var.environment}-master-${element(var.availability_zones, 0)}"
  }
}

# Create instance
resource "aws_instance" "ipa-master-2" {
  ami = "${var.ipa_server_ami}"
  availability_zone = "${element(var.availability_zones, 1)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ipa-server-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet2.id}"
  associate_public_ip_address = false
  tags {
     Name = "${var.project}-${var.environment}-master-${element(var.availability_zones, 1)}"
  }
}
# Create ELB
resource "aws_elb" "ipa-elb" {
  name = "ipa-${var.environment}-elb"
  subnets = ["${aws_subnet.public-subnet1.id}","${aws_subnet.public-subnet2.id}"]
  security_groups = ["${aws_security_group.ipa-elb-sg.id}"]
   
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
  instances = ["${aws_instance.ipa-openvpn-proxy-1.id}","${aws_instance.ipa-openvpn-proxy-2.id}"]
    
  tags = {
     Name = "ipa-${var.environment}-elb"
  }
}


# Create instance
resource "aws_instance" "ipa-openvpn-proxy-1" {
  ami = "${var.ipa_openvpn_proxy_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ipa-mgmt-public-subnet-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet2.id}"
  associate_public_ip_address = false
  tags {
     Name = "${var.project}-${var.environment}-openvpn-proxy-${element(var.availability_zones, 0)}"
  }
}

# Create instance
resource "aws_instance" "ipa-openvpn-proxy-2" {
  ami = "${var.ipa_openvpn_proxy_ami}"
  availability_zone = "${element(var.availability_zones, 1)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ipa-mgmt-public-subnet-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet2.id}"
  associate_public_ip_address = false
  tags {
     Name = "${var.project}-${var.environment}-openvpn-proxy-${element(var.availability_zones, 1)}"
  }
}
