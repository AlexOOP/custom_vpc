resource "aws_vpc" "custom_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    tags = {
        Name = "${var.name}-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
    count = 3
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone = "${var.region}${element(["a", "b", "c"], count.index)}"
    tags = {
      Name = "${var.name}-public-subnet-${element(["a", "b", "c"], count.index)}"
    }
}

resource "aws_subnet" "private_subnet" {
    count = 3
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    availability_zone = "${var.region}${element(["a", "b", "c"], count.index)}"
    tags = {
      Name = "${var.name}-private-subnet-${element(["a", "b", "c"], count.index)}"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
      Name = "${var.name}-public-route-table"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
      Name = "${var.name}-igw"
    }
}

resource "aws_route" "public_subnet_route" {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association" {
    count = 3
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_key_pair" "public_ssh_key" {
    key_name = "public_ssh_key"
    public_key = file(pathexpand(var.public_key))
}

resource "aws_instance" "public_ec2_instance" {
    ami = data.aws_ami.ubuntu_24_arm.id
    instance_type = var.instance_type
    subnet_id = element(aws_subnet.public_subnet[*].id, random_integer.subnet_index.result)
    vpc_security_group_ids = [aws_security_group.public_sg.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.public_ssh_key.key_name
    
    user_data = <<EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    EOF

    tags = {
      Name = "${var.name}-public-instance"
    }  

    lifecycle {
        ignore_changes = [ subnet_id ]
    }
}

resource "random_integer" "subnet_index" {
    min = 0
    max = 2
}

resource "aws_security_group" "public_sg" {
    vpc_id = aws_vpc.custom_vpc.id
    name = "public_sg"

    dynamic "ingress" {
        for_each = ["22", "80"]
        content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress = {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.name}-public-sg"
    }
}

resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.custom_vpc.id
    name = "private_sg"

    dynamic "ingress" {
        for_each = ["22"]
        content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            security_groups = [ aws_security_group.public_sg.id ]
        }
    }

    egress = {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.name}-private-sg"
    }
}
