terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "admin" {
  key_name   = "admin-keyfor-lab07"
  public_key = file(var.path_to_ssh_public_key)
}

locals {
  vms = {
    app = {},
    db  = {}
  }
  # This next line is a bit complicated... if you allow all IP addresses, then
  # the CIDR is "0.0.0.0/0" (everybody), if not then it's your IP address
  # with a "/32" suffix which means just one IP address. 
  # See https://cidr.xyz/ to learn more about the CIDR notation for IP addresses.
  allowed_cidrs_for_db = var.allow_all_ip_addresses_to_access_database_server ? ["0.0.0.0/0"] : ["${var.my_ip_address}/32"]
}

resource "aws_instance" "servers" {
  for_each = local.vms

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name        = aws_key_pair.admin.key_name
  security_groups = [aws_security_group.vms.name]

  tags = {
    Name = "${each.key} server for lab07"
  }
}

resource "aws_security_group" "vms" {
  name = "vms_for_lab07"

  # SSH
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP in
  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL in
  ingress {
    from_port   = 0
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidrs_for_db
  }

  # ICMP (Ping)
  ingress {
    from_port   = -1  # Allows all ICMP types
    to_port     = -1  # Allows all ICMP types
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # Change this if you want to restrict it
  }

  # HTTPS out
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vm_public_addresses" {
  value = { for role_name, vm in aws_instance.servers : role_name => {
    public_hostname   = vm.public_dns,
    public_ip_address = vm.public_ip
    }
  }
}
