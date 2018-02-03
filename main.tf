provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "example" {
  ami           = "ami-5652ce39"
  instance_type = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    echo "hola caracola" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws.aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
