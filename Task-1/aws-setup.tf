## Enter provider details with access key and secret key
    ## Create access key and secret key first and then run the .tf file
provider "aws" {
    region = "us-east-1"
    access_key = "xxxxxxxxxxxxxx"
    secret_key = "xxxxxxxxxxxxxx"
}


## Create VPC
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
      Name = "My-VPC"
    }
}


## Create two public subnets
resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"

    tags = {
      Name = "Public-Subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"

    tags = {
      Name = "Public-Subnet-2"
    }
}


## Create two private subnets
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"

    tags = {
      Name = "Private-Subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"

    tags = {
      Name = "Private-Subnet-2"
    }
}


## Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
      Name = "My-IGW"
    }
}


## Create Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}


## Create NAT Gateway
resource "aws_nat_gateway" "my_nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet_1.id
    depends_on = [ aws_internet_gateway.my_igw ]

    tags = {
      Name = "My-NAT-GW"
    }
}


## Create Public Route Table for Internet Gateway
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }

    tags = {
      Name = "Public-Route-Table"
    }
}


## Create Private Route Table for NAT Gateway
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.my_nat_gw.id
    }

    tags = {
      Name = "Private-Route-Table"
    }
}


## Route Table associations
resource "aws_route_table_association" "public_subnet_1_association" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
    subnet_id = aws_subnet.public_subnet_2.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
    subnet_id = aws_subnet.private_subnet_1.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
    subnet_id = aws_subnet.private_subnet_2.id
    route_table_id = aws_route_table.private_rt.id
}


## Create key-pair for SSH login
resource "tls_private_key" "aws_key" {
    algorithm = "RSA"
    rsa_bits = 2048
}

resource "aws_key_pair" "aws_key" {
    key_name = "aws-key"
    public_key = tls_private_key.aws_key.public_key_openssh
}

resource "local_file" "private_key" {
    content = tls_private_key.aws_key.private_key_pem
    filename = "/Path/to/the/file/aws-key.pem"
}


## Create Security Group
resource "aws_security_group" "my_sg" {
    vpc_id = aws_vpc.my_vpc.id
    description = "Allow inbound SSH and HTTP traffic"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "My-Security-Group"
    }
}


## Deploy 2 EC2 instances
resource "aws_instance" "aws_app_machine" {
    ami = "ami-04b4f1a9cf54c11d0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_1.id
    security_groups = [aws_security_group.my_sg.id]
    key_name = aws_key_pair.aws_key.key_name
    
    tags = {
      Name = "aws-app-machine"
    }
}

resource "aws_instance" "aws_tools_machine" {
    ami = "ami-04b4f1a9cf54c11d0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_2.id
    security_groups = [aws_security_group.my_sg.id]
    key_name = aws_key_pair.aws_key.key_name
    
    tags = {
      Name = "aws-tools-machine"
    }
}
