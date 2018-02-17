provider "aws" {
  region = "eu-central-1"
}

# Declare the data source
data "aws_availability_zones" "available" {}

variable "availability_zones" {
  type = "list"
  default = ["eu-central-1b", "eu-central-1a"]
}

variable "server_port" {
  description = "port for the web server"
  default     = 8080
}

variable "external_port" {
  description = "external port for the web server"
  default     = 80
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-af79ebc0"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.example.id}"]

  user_data = <<-EOF
    #!/bin/bash
    echo "----user_data start"
    echo "hola caracola" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    echo "----user_data stop"
    EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" example {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones   = ["${data.aws_availability_zones.available.names}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform asg example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"

  #another way of specifying the az, because aws_availability zones include zones that have no subnet...
  availability_zones = ["${var.availability_zones}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = "${var.external_port}"
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "example" {
  name = "terraform-example-instance"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb" {
  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = "${var.external_port}"
    to_port     = "${var.external_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    #to allow healthchecks
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
