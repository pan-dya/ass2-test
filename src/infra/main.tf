terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name = "assignment2"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet1"
  }
}


#public-subnet2 creation
resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "public-subnet2"
  }
}

#private-subnet1 creation
resource "aws_subnet" "private-subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet1"
  }
}

resource "aws_internet_gateway" "main-gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gateway.id
  }
  tags = {
    Name = "route to internet"
  }
}

#route 1
resource "aws_route_table_association" "route1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.route.id
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
    app1 = {},
    app2= {},
    db  = {}
  }
  # This next line is a bit complicated... if you allow all IP addresses, then
  # the CIDR is "0.0.0.0/0" (everybody), if not then it's your IP address
  # with a "/32" suffix which means just one IP address. 
  # See https://cidr.xyz/ to learn more about the CIDR notation for IP addresses.
  allowed_cidrs_for_db = var.allow_all_ip_addresses_to_access_database_server ? ["0.0.0.0/0"] : ["${var.my_ip_address}/32"]
}

resource "aws_security_group" "vms" {
  name = "vms"
  vpc_id = aws_vpc.main.id

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
  
  # HTTP in
  ingress {
    from_port   = 0
    to_port     = 81
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

  # HTTP out
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS out
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL out
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP out
  egress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "servers" {
  for_each = local.vms

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = each.key == "db" ? aws_subnet.private-subnet1.id : aws_subnet.public-subnet1.id
  key_name        = aws_key_pair.admin.key_name
  security_groups = [aws_security_group.vms.id]

  tags = {
    Name = "${each.key}"
  }
  depends_on = [aws_security_group.vms]
}

# Load Balancer Creation
resource "aws_lb" "external-alb" {
  name               = "loadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vms.id]
  subnets            = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]

  depends_on = [aws_security_group.vms]
}

resource "aws_lb_target_group" "target_elb" {
  name     = "targetGroupAss2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path     = "/health"
    port     = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "servers" {
  for_each          = aws_instance.servers  # Use for_each to attach each instance
  target_group_arn  = aws_lb_target_group.target_elb.arn
  target_id         = each.value.id          # Reference the instance ID
  port              = 80

  depends_on = [
    aws_lb_target_group.target_elb,
    aws_instance.servers, 
  ]
}

resource "aws_lb_listener" "listener_elb" {
  load_balancer_arn = aws_lb.external-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_elb.arn
  }
}


output "vm_ip_addresses" {
  value = { for role_name, vm in aws_instance.servers : role_name => {
    public_hostname   = vm.public_dns,
    public_ip_address = vm.public_ip
    private_ip_address = vm.private_ip
    }
  }
}
