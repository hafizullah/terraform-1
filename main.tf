# AWS access details

provider "aws" {
  shared_credentials_file = "${var.home_dir}/.aws/credentials"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

# Create Management VPC
resource "aws_vpc" "awstraining-mgmt-vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

# Create security group for Public Subnet
resource "aws_security_group" "awstraining-mgmt-public-subnet-sg" {
  name        = "awstraining-${var.environment}-mgmt-public-subnet-sg "
  description = "Security group for Public Subnets"
  vpc_id      = "${aws_vpc.awstraining-mgmt-vpc.id}"
  # inbound ssh access from FEYE DC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.feyedc_cidr_block}"] # to be replaced with FEYE DC CIDR Block
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.remote_vpc_cidr_block}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh_outbound_access_to_awstraining" {
  type = "egress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}


resource "aws_security_group_rule" "allow_icmp_from_mgmt_public_subnet_hosts" {
  type = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "allow_ssh_from_mgmt_public_subnet_hosts" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "https_outbound" {
  type = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}

# Create Command Control Jump Box
resource "aws_instance" "ccjumpbox" {
  ami = "${var.ccjumpbox_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.awstraining-mgmt-public-subnet-sg.id}","${aws_security_group.awstraining-server-sg.id}"]
  subnet_id = "${aws_subnet.public-subnet1.id}"
  associate_public_ip_address = true
  source_dest_check = false
  # Deploy ansible on the jump box
  #user_data = "${file("install-ansible.sh")}"
  #count     = "${var.count}"
  lifecycle {
     ignore_changes = ["ami", "user_data"]
  }

  tags {
     Name = "awstraining-${var.environment}-ccjumpbox"
  }

}

resource "aws_eip" "ccjumpbox-ip" {
  instance = "${aws_instance.ccjumpbox.id}"
  vpc = true
  connection {
     host = "${aws_eip.ccjumpbox-ip.public_ip}"
     user = "ubuntu"
     timeout = "90s"
     private_key = "${file(var.private_key)}"
     agent = false
  }

  provisioner "file" {
    source      = "${var.private_key}"
    destination = "~/.ssh/${var.key_name}.pem"
  }
  }


  provisioner "remote-exec" {
    inline = [
      "chmod 0400 ~/.ssh/${var.key_name}.pem",
    ]
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "awstraining-vpc-igw" {
  vpc_id = "${aws_vpc.awstraining-mgmt-vpc.id}"
  tags {
     Name = "awstraining-${var.project}-igw"
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
  vpc_id                  = "${aws_vpc.awstraining-mgmt-vpc.id}"
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
  vpc_id = "${aws_vpc.awstraining-mgmt-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.awstraining-vpc-igw.id}"
  }

  route {
    cidr_block = "${var.remote_vpc_cidr_block}"
    instance_id = "${aws_instance.awstraining-openvpn-proxy-1.id}"
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

# Public Subnet2 in AZ2
resource "aws_subnet" "public-subnet2" {
  vpc_id                  = "${aws_vpc.awstraining-mgmt-vpc.id}"
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
  vpc_id = "${aws_vpc.awstraining-mgmt-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.awstraining-vpc-igw.id}"
  }
  route {
    cidr_block = "${var.remote_vpc_cidr_block}"
    instance_id = "${aws_instance.awstraining-openvpn-proxy-1.id}"
  }
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-public-subnet"
  }
}
# Private Subnet1 in AZ1
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = "${aws_vpc.awstraining-mgmt-vpc.id}"
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
  vpc_id = "${aws_vpc.awstraining-mgmt-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }

  route {
    cidr_block = "${var.remote_vpc_cidr_block}"
    instance_id = "${aws_instance.awstraining-openvpn-proxy-1.id}"
  }
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 0)}-private-subnet"
  }
}


# Private Subnet2 in AZ2
resource "aws_subnet" "private-subnet2" {
  vpc_id                  = "${aws_vpc.awstraining-mgmt-vpc.id}"
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
  vpc_id = "${aws_vpc.awstraining-mgmt-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw2.id}"
  }
  route {
    cidr_block = "${var.remote_vpc_cidr_block}"
    instance_id = "${aws_instance.awstraining-openvpn-proxy-1.id}"
  }
  tags {
    Name = "${var.vpc_name}-${element(var.availability_zones, 1)}-private-subnet"
  }
}
# Create security group for awstraining server
resource "aws_security_group" "awstraining-server-sg" {
  name        = "awstraining-${var.environment}-awstrainingsrv-sg"
  description = "Security group for FreeIPA"
  vpc_id      = "${aws_vpc.awstraining-mgmt-vpc.id}"

  # inbound ssh access from FEYE VPN Servers/DC Server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.feyedc_cidr_block}"]
  }

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
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "SSH_access_from_self" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_ELB" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-elb-sg.id}"
}
resource "aws_security_group_rule" "HTTPS_access_from_CC_JumpBoxes" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
}
resource "aws_security_group_rule" "HTTP_access_from_port_80" {
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Port_88_inbound_access_from_self_sg" {
  type = "ingress"
  from_port   = 88
  to_port     = 88
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "udp_Port_88_inbound_access_from_self_sg" {
  type = "ingress"
  from_port   = 88
  to_port     = 88
  protocol    = "udp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "LDAP_access_from_self_sg" {
  type = "ingress"
  from_port   = 389
  to_port     = 389
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_HTTPS_access_from_self_sg" {
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_udp_port_464_from_self_sg" {
  type = "ingress"
  from_port   = 464
  to_port     = 464
  protocol    = "udp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_464_from_self_sg" {
  type = "ingress"
  from_port   = 464
  to_port     = 464
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_port_636_from_self_sg" {
  type = "ingress"
  from_port   = 636
  to_port     = 636
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "Allow_UDP_access_from_self_sg" {
  type = "ingress"
  from_port   = 123
  to_port     = 123
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}


resource "aws_security_group_rule" "allow_icmp_from_awstraining_servers" {
  type = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  security_group_id = "${aws_security_group.awstraining-server-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}

# Create security group for elb
resource "aws_security_group" "awstraining-elb-sg" {
  name        = "awstraining-${var.environment}-elb-sg"
  description = "Security group for ELB"
  vpc_id      = "${aws_vpc.awstraining-mgmt-vpc.id}"
  # Inbound internet access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "https_outbound_access_to_awstraining" {
  type = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = "${aws_security_group.awstraining-elb-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "icmp_outbound_access_to_awstraining" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.awstraining-elb-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-server-sg.id}"
}
resource "aws_security_group_rule" "ping_outbound_access_to_public_subnets" {
  type = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  security_group_id = "${aws_security_group.awstraining-elb-sg.id}"
  source_security_group_id = "${aws_security_group.awstraining-mgmt-public-subnet-sg.id}"
}


# Create instance
resource "aws_instance" "awstraining-master-1" {
  ami = "${var.awstraining_server_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.awstraining-server-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet1.id}"
  associate_public_ip_address = false

  tags {
     Name = "${var.project}-${var.environment}-master-${element(var.availability_zones, 0)}"
  }
}

# Create instance
resource "aws_instance" "awstraining-master-2" {
  ami = "${var.awstraining_server_ami}"
  availability_zone = "${element(var.availability_zones, 1)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.awstraining-server-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet2.id}"
  associate_public_ip_address = false
  tags {
     Name = "${var.project}-${var.environment}-master-${element(var.availability_zones, 1)}"
  }
}
# Create ELB
resource "aws_elb" "awstraining-elb" {
  name = "${var.project}-${var.environment}-elb"
  subnets = ["${aws_subnet.public-subnet1.id}","${aws_subnet.public-subnet2.id}"]
  security_groups = ["${aws_security_group.awstraining-elb-sg.id}"]

  listener {
	instance_port = 443
        instance_protocol = "https"
	lb_port = 443
	lb_protocol = "https"
	ssl_certificate_id = "${var.ssl_certificate}"
  }
  health_check {
        healthy_threshold = 2
	unhealthy_threshold = 2
	timeout = 3
	target = "HTTPs:443/index.html"
	interval = 30
  }

  instances = ["${aws_instance.awstraining-openvpn-proxy-1.id}","${aws_instance.awstraining-openvpn-proxy-2.id}"]

  tags = {
     Name = "${var.project}-${var.environment}-elb"
  }
}
resource "aws_lb_cookie_stickiness_policy" "awstraining-elb-cookie" {
  name = "${var.project}-elb-policy"
  load_balancer = "${aws_elb.awstraining-elb.id}"
  lb_port = 443
}

# Create instance
resource "aws_instance" "awstraining-openvpn-proxy-1" {
  ami = "${var.awstraining_openvpn_proxy_ami}"
  availability_zone = "${element(var.availability_zones, 0)}"
  instance_type = "${var.instance_type}"
  source_dest_check = false
  associate_public_ip_address = true
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.awstraining-mgmt-public-subnet-sg.id}","${aws_security_group.awstraining-server-sg.id}","${aws_security_group.awstraining-elb-sg.id}"]
  subnet_id = "${aws_subnet.public-subnet1.id}"

  tags {
     Name = "${var.project}-${var.environment}-openvpn-proxy-${element(var.availability_zones, 0)}"
  }
}

resource "aws_eip" "openvpn-proxy-1-ip" {
  instance = "${aws_instance.awstraining-openvpn-proxy-1.id}"
  vpc = true
}

# Create instance
resource "aws_instance" "awstraining-openvpn-proxy-2" {
  ami = "${var.awstraining_openvpn_proxy_ami}"
  availability_zone = "${element(var.availability_zones, 1)}"
  instance_type = "${var.instance_type}"
  source_dest_check = false
  associate_public_ip_address = true
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.awstraining-mgmt-public-subnet-sg.id}","${aws_security_group.awstraining-server-sg.id}","${aws_security_group.awstraining-elb-sg.id}"]
  subnet_id = "${aws_subnet.public-subnet2.id}"
  tags {
     Name = "${var.project}-${var.environment}-openvpn-proxy-${element(var.availability_zones, 1)}"
  }
}

resource "aws_eip" "openvpn-proxy-2-ip" {
  instance = "${aws_instance.awstraining-openvpn-proxy-2.id}"
  vpc = true
}
