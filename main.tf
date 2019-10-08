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
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
}

resource "aws_security_group" "terraform-sg" {
  name = "terraform-sg"
  description = "Allow HTTP requests"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use to make HTTP requests."
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}
