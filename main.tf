###
# ami
###
data "aws_ami" "ipamaster" {
  most_recent = true

  filter {
    name   = "name"
    values = ["base-bootstrap-${var.ami_version}"]
  }

  filter {
    name   = "tag:Created_By"
    values = ["${var.ami_user}"]
  }
}

###
# security_groups
###
resource "aws_security_group" "ipamaster" {
  name        = "${var.cust_id}-${var.product}-ipamaster"
  description = "Security Group for jump boxes - allow port 22 from VPN"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${split(",",(lookup(var.secure_ingress, var.target)))}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.cust_id}-${var.product}-ipamaster"
    ManagedBy   = "terraform"
    vpc_id      = "${var.vpc_id}"
    cust-id     = "${var.cust_id}"
    product     = "${var.product}"
    designation = "${var.designation}"
    environment = "${var.environment}"
    mgmt        = "${var.mgmt}"
  }
}

resource "aws_instance" "ipamaster" {
  ami                  = "${data.aws_ami.ipamaster.id}"
  source_dest_check    = false
  instance_type        = "${var.instance_type}"
  subnet_id            = "${element(var.subnet_ids, count.index)}"
  key_name             = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  user_data            = "${data.template_file.ipamaster.rendered}"
  count                = "${var.count}"

  root_block_device {
    volume_size = "${var.root_block_device}"
  }

  vpc_security_group_ids = [
    "${aws_security_group.ipamaster.id}",
    "${split(",",var.security_groups)}",
  ]

  lifecycle {
    ignore_changes = ["ami", "user_data"]
  }

  tags {
    Name        = "${var.cust_id}-${var.product}-ipamaster0${count.index + 1}"
    ManagedBy   = "terraform"
    vpc_id      = "${var.vpc_id}"
    cust-id     = "${var.cust_id}"
    product     = "${var.product}"
    designation = "${var.designation}"
    environment = "${var.environment}"
    mgmt        = "${var.mgmt}"
  }

  provisioner "file" {
    source      = "${var.private_key}"
    destination = "~/.ssh/id_rsa"

    connection {
      user        = "ubuntu"
      private_key = "${file(var.private_key)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0400 ~/.ssh/id_rsa",
    ]

    connection {
      user        = "ubuntu"
      private_key = "${file(var.private_key)}"
    }
  }
}

resource "aws_eip" "ipamaster" {
  instance = "${element(aws_instance.ipamaster.*.id, count.index)}"
  vpc      = true
  count    = "${var.count}"
}
