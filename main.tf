#SETUP
terraform {
 required_providers {
   aws = {
     source = "hashicorp/aws"
   }
 }
 backend "s3" {
   region = "us-east-1"
   key    = "terraform.tfstate"
 }
}

provider "aws" {
  region  = "us-east-1"
}

#RESOURCES
# Create the VPC with the subnets
resource "aws_vpc" "hoh-app-vpc" {
  cidr_block = "10.64.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "hoh-app-vpc"
  }
}

resource "aws_subnet" "SubnetProd" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  cidr_block = "10.64.0.0/20"
  tags = {
    Name = "sn-hoh-prod"
  }
}

resource "aws_subnet" "SubnetDev" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  cidr_block = "10.64.16.0/20"
  tags = {
    Name = "sn-hoh-dev"
  }
}

#Create Internet Gateway and attach it
resource "aws_internet_gateway" "hoh-app-igw" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  tags = {
    Name = "hoh-app-igw"
  }
}

#Create Route Table and Associations
resource "aws_route_table" "hoh-app-web-rt" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hoh-app-igw.id
  }
}

# resource "aws_route" "main-route" {
  
# }
resource "aws_route_table_association" "prod" {
  subnet_id = aws_subnet.SubnetProd
  route_table_id = aws_route_table.hoh-app-web-rt
}
resource "aws_route_table_association" "dev" {
  subnet_id = aws_subnet.SubnetDev
  route_table_id = aws_route_table.hoh-app-web-rt
}

#Create Security Groups
resource "aws_security_group" "prod-sg" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  name = "prod-sg"
  description = "Enable SSH, HTTP, and ICMP access for production server"
  #Need to re-allow all egress due to terraform stripping the allow-all-out
  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all traffic out"
    from_port = 0
    protocol = -1
    to_port = 0
  } ]
  tags = {
    Name = "prod-sg"
  }  
}
resource "aws_security_group" "dev-sg" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  name = "dev-sg"
  description = "Enable SSH, HTTP, 8080, and ICMP access for Jenkins server"
  #Need to re-allow all egress due to terraform stripping the allow-all-out
  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all traffic out"
    from_port = 0
    protocol = -1
    to_port = 0
  } ]  
  tags = {
    Name = "dev-sg"
  }
}

    #Prod-sg rules
resource "aws_security_group_rule" "ssh-prod" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.prod-sg.id
  ingress = {
    description = "Allow SSH IPv4 IN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "http-prod" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.prod-sg.id
  ingress = {
    description = "Allow HTTP IPv4 IN"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "icmp-prod" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.prod-sg.id
  ingress = {
    description = "Allow ICMP Between Subnets"
    from_port = 8
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.64.0.0/16"]
  }
}

    #Dev-sg rules
resource "aws_security_group_rule" "ssh-dev" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.dev-sg.id
  ingress = {
    description = "Allow SSH IPv4 IN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "jenkins-dev" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.dev-sg.id
  ingress = {
    description = "Allow Jenkins 8080 IPv4 IN"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "icmp-dev" {
  vpc_id = "${aws_vpc.hoh-app-vpc.id}"
  security_group_id = aws_security_group.dev-sg.id
  ingress = {
    description = "Allow ICMP Between Subnets"
    from_port = 8
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.64.0.0/16"]
  }
}

#Create Session Manager Role and Add to Instace Profile
resource "aws_iam_instance_profile" "session-manager-instance-profile" {
  name = "session-manager-instance-profile"
  role = aws_iam_role.session-manager-role
  path = "/"
}

resource "aws_iam_role" "session-manager-role" {
  name = "session-manager-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }  
}

resource "aws_iam_policy" "root" {
  name = "root"
  path = "/"
  policy = data.aws_iam_policy_document.policy-for-role
}

data "aws_iam_policy_document" "policy-for-role" {
  statement {
    actions   = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
      ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    actions   = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
      ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    actions   = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
      ]
    resources = ["*"]
    effect = "Allow"
  }     
}

resource "aws_iam_policy_attachment" "default" {
  role = aws_iam_role.session-manager-role.name
  policy_arn = aws_iam_policy.root.arn
}


#Create the Instances
resource "aws_instance" "web_server" {
  ami           = var.images["PROD"]
  instance_type = "t2.micro"
  # subnet_id = aws_subnet.SubnetProd
  vpc_security_group_ids = [ "${aws_security_group.prod-sg.id}" ]
  # private_ip = "10.64.10.1"
  associate_public_ip_address = "true"
  iam_instance_profile = aws_iam_instance_profile.session-manager-instance-profile
  
  tags = {
    Name = "hoh-prod"
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = var.images["DEV"]
  instance_type = "t2.micro"
  # subnet_id = aws_subnet.SubnetDev
  vpc_security_group_ids = [ "${aws_security_group.dev-sg.id}" ]
  # private_ip = "10.64.20.1"
  associate_public_ip_address = "true"
  iam_instance_profile = aws_iam_instance_profile.session-manager-instance-profile

  tags = {
    Name = "hoh-dev"
  }
}

#Network Interfaces
resource "aws_network_interface" "prod-interface" {
  subnet_id       = aws_subnet.SubnetProd.id
  private_ips     = ["10.64.10.1"]
  security_groups = [aws_security_group.prod-sg.id]

  attachment {
    instance     = aws_instance.web_server.id
    device_index = 0
  }
}

resource "aws_network_interface" "dev-interface" {
  subnet_id       = aws_subnet.SubnetDev
  private_ips     = ["10.64.20.1"]
  security_groups = [aws_security_group.dev-sg.id]

  attachment {
    instance     = aws_instance.jenkins_server.id
    device_index = 0
  }
}

# #Outputs
# output "hoh-vpc" {
#   description = "HoH VPC1"
#   value = aws_vpc.hoh-app-vpc
# }

# output "hohvpcsubnetprod" {
#   description = "HoH VPC1 Subnet Production"
#   value = aws_subnet.SubnetProd
# }

# output "hohvpvsubnetdev" {
#   description = "HoH VPC1 Subnet Development"
#   value = aws_subnet.SubnetDev
# }