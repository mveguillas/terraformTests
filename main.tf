provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "instance" {
  ami                    = "ami-af79ebc0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
    #!/bin/bash
    echo "----user_data start"
    echo "hola caracola" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    echo "----user_data stop"
    EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
variable "server_port"{
  description = "port for the web server"
  default = 8080
}
output "public_ip"{
  value = "${aws_instance.instance.public_ip}"
}
output "public_dns"{
  value = "${aws_instance.instance.public_dns}"
}