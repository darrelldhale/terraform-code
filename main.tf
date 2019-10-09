provider "aws" {
  region = "us-east-1"
}

# Launch configuration for the Auto scaling group
resource "aws_launch_configuration" "launch-config" {
  image_id  = "ami-04b9e92b5572fa0d1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.terraform-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!!!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web-lb"  {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg-listener" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    field = "path-pattern"
    values = ["*"]
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web-target.arn
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port = var.alb_port_inbound
    to_port = var.alb_port_inbound
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = var.alb_port_outbound
    to_port = var.alb_port_outbound
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "web-target" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "web-asg" {
  launch_configuration = aws_launch_configuration.launch-config.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.web-target.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

variable "server_port" {
  description = "The port the server will use to make HTTP requests."
  type = number
  default = 8080
}

variable "alb_port_inbound" {
  description = "The port the load balancer will use to allow traffic"
  type = number
  default = 80
}

variable "alb_port_outbound" {
  description = "The port the load balancer will use to allow outbound traffic"
  type = number
  default = 0
}

output "alb_dns_name" {
  value = aws_lb.web-lb.dns_name
  description = "The domain name of the load balancer"
}
