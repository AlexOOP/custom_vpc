variable "region" {
    default = "eu-west-2"
}

variable "vpc_cidr" {
    default = "10.50.0.0/16"
}

variable "instance_type" {
    default = "t4g.small"
}

variable "name" {
    default = "AlexTest"
}

variable "public_key" {
    default = "~/.ssh/id_rsa.pub"
}

data "aws_ami" "ubuntu_24_arm" {
    most_recent = true
    owners = ["099720109477"]
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    filter {
      name = "root-device-type"
      values = ["ebs"]
    }
}
