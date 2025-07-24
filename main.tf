provider "aws" {
  region = var.aws_region
}

# Data sources for existing infrastructure
data "aws_vpc" "existing" {
  id = "vpc-0b75b0de8410ced50"
}

data "aws_subnet" "subnet_1" {
  id = "subnet-06b890f36c1d8aa84"
}
data "aws_subnet" "subnet_2" {
  id = "subnet-0c512f1685f3cf34b"
}
data "aws_subnet" "subnet_3" {
  id = "subnet-058ff11acd1ee121d"
}
data "aws_subnet" "subnet_4" {
  id = "subnet-02f1c80839068cabe"
}
data "aws_subnet" "subnet_5" {
  id = "subnet-0c6014d16d826cc10"
}
data "aws_subnet" "subnet_6" {
  id = "subnet-0bb037e2c138aff42"
}

data "aws_security_group" "existing" {
  id = "sg-05e0b063a67841948"
}

data "aws_route_table" "existing" {
  id = "rtb-0d75255b2973bdd63"
}

data "aws_instance" "existing" {
  instance_id = "i-09d300c017411c249"
}

data "aws_iam_role" "support" {
  name = "AWSServiceRoleForSupport"
}

data "aws_iam_role" "trusted_advisor" {
  name = "AWSServiceRoleForTrustedAdvisor"
}

data "aws_iam_user" "dv" {
  user_name = "DV"
}

# Example of restricted security group rule management (if you need to update it)
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = data.aws_security_group.existing.id
  cidr_blocks       = ["YOUR_WHITELISTED_IP/32"]
  description       = "SSH access from trusted IP"
}

output "ec2_instance_public_ip" {
  value = data.aws_instance.existing.public_ip
}
