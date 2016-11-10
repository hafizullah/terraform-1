resource "aws_eip" "demo" {
  instance = "${aws_instance.TS-demo.id}"
  depends_on = ["aws_instance.TS-demo"]
  vpc      = true
}

resource "aws_instance" "TS-demo" {
  ami                    = "${lookup(var.aws_opsman_ami,var.region)}"
  instance_type          = "m3.medium"
  key_name               = "${var.key_name}"
  subnet_id              = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.all_pass.id}"]

  tags {
    Name = "demo"
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.TS-demo.private_ip} > private_ips"
  }

}
resource "null_resource" "preparation" {
    triggers {
        instance = "${aws_instance.TS-demo.id}"
    }
  connection {
    host        ="${aws_eip.demo.public_ip}"   # don't forget  this option.
    user        = "ubuntu"
    timeout     = "30s"
    private_key = "${file("./skyfree.pem")}"
    agent = false
  }

  provisioner "file" {
    source      = "./tfvars"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
    ]
  }

}
