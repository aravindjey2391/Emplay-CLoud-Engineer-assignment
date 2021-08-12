provider "aws" {
  region = "us-east-1"
  access_key = "access_key"
  secret_key = "Secret_key"
}

# 1 Create a VPC
resource "aws_vpc" "task-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Task-VPC"
  }
}

# 2 Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.task-vpc.id
}

# 3. Route Table
resource "aws_route_table" "Task-routetable" {
  vpc_id = aws_vpc.task-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
    route {
    
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  tags = {
    Name = "Task-Routetable"
  }
}

# 4 Subnet
resource "aws_subnet" "subnet-1" {
    vpc_id=aws_vpc.task-vpc.id
    cidr_block="10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name="Task-Subnet"
    }
}

# 5 Associating subnet with Route Table
resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.Task-routetable.id
}

# 6. Security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.task-vpc.id

  ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
   ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "allow_web"
  }
}

# 7.Network interface

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8 Elastic ip

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 9 ubuntu instance


resource "aws_ebs_volume" "second_drive" {
  availability_zone = "us-east-1a"
  size              = 8

  tags = {
    Name = "second_drive"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.second_drive.id
  instance_id = aws_instance.web-task-server.id
}
resource "aws_instance" "web-task-server" {
    ami="ami-0747bdcabd34c712a"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "ubuntu"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
      
    }           
     tags={
                Name= "Terraform-web-server"
            }

}
