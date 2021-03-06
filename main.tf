variable "project" {
  default = "itatest"
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  tags {
    Name = "main"
    Project = "${var.project}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "gw"
    Project = "${var.project}"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.0.0/24"
  tags {
    Name = "public"
    Project = "${var.project}"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "public_route"
    Project = "${var.project}"
  }
}

resource "aws_route_table_association" "public_route" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_security_group" "bastion" {
  vpc_id = "${aws_vpc.main.id}"
  name = "bastion"
  description = "Bastion server"
  tags {
    Name = "bastion"
    Project = "${var.project}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal" {
  vpc_id = "${aws_vpc.main.id}"
  name = "internal"
  description = "Allow all internal inbound traffic"
  tags {
    Name = "internal"
    Project = "${var.project}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_internal" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = "${aws_security_group.internal.id}"
  source_security_group_id = "${aws_security_group.internal.id}"
}

resource "aws_instance" "bastion" {
  ami = "ami-383c1956"
  instance_type = "t2.micro"
  key_name = "itatest"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
    "${aws_security_group.internal.id}"
  ]
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = "true"
  tags {
    Name = "bastion"
    Project = "${var.project}"
  }
}
