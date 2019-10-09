#!/bin/bash
terraform apply
load_balancer_dns=$(terraform output alb_dns_name)
curl http://$load_balancer_dns:80

