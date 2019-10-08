#!/bin/bash
terraform apply
public_ip=$(terraform output public_ip)

curl http://$public_ip:8080
