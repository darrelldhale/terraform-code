provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami = "ami-04b9e92b5572fa0d1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]

  tags = {
    Name = "terraform-example"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!!!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_security_group" "terraform-sg" {
  name = "terraform-sg"
  description = "Allow HTTP requests"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


