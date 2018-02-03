provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "example" {
  ami           = "ami-5652ce39"
  instance_type = "t2.micro"
  tags {
    Name = "terraform-example3"
  }
}

