provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "private_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "private_ingress_api" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "private_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.private_sg.id
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-0e86e20dae9224db8" # Update with the latest ubuntu Linux  AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "BastionHost"
  }
}

# Master Nodes
resource "aws_instance" "master" {
  count                  = 1
  ami                    = "ami-0e86e20dae9224db8" # Update with the latest ubuntu Linux  AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  availability_zone      = "us-east-1a"
  root_block_device {
    volume_size = 10 # Size in GB
    volume_type = "gp2" # General Purpose SSD (gp2)
  }
  key_name = var.key_name

  tags = {
    Name = "Master${count.index + 1}"
  }
}

# Worker Nodes
resource "aws_instance" "worker" {
  count                  = 1
  ami                    = "ami-0e86e20dae9224db8" # Update with the latest ubuntu Linux  AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  availability_zone      = "us-east-1a"
  root_block_device {
    volume_size = 10 # Size in GB
    volume_type = "gp2" # General Purpose SSD (gp2)
  }
  key_name = var.key_name

  tags = {
    Name = "Worker${count.index + 1}"
  }
}

# Output Bastion Host Public IP
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Output Master Nodes Private IPs
output "master_private_ips" {
  value = aws_instance.master[*].private_ip
}

# Output Worker Nodes Private IPs
output "worker_private_ips" {
  value = aws_instance.worker[*].private_ip
}



















# provider "aws" {
#   region = "us-east-1"
# }

# # VPC
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# # Public Subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "us-east-1a"
# }

# # Private Subnet
# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1a"
# }

# # Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id
# }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Security Groups
# resource "aws_security_group" "bastion_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.main.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group_rule" "private_ingress_ssh" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.bastion_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_api" {
#   type                     = "ingress"
#   from_port                = 6443
#   to_port                  = 6443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_kubelet" {
#   type                     = "ingress"
#   from_port                = 10250
#   to_port                  = 10250
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# # Bastion Host
# resource "aws_instance" "bastion" {
#   ami                    = "ami-0fe630eb857a6ec83" # Update with the latest Amazon Linux 2 AMI
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]
#   key_name               = var.key_name

#   tags = {
#     Name = "BastionHost"
#   }
# }

# # Master Nodes
# resource "aws_instance" "master" {
#   count                  = 1
#   ami                    = "ami-0fe630eb857a6ec83" # Update with the latest Amazon Linux 2 AMI
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   availability_zone      = "us-east-1a"
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Master${count.index + 1}"
#   }
# }

# # Worker Nodes
# resource "aws_instance" "worker" {
#   count                  = 1
#   ami                    = "ami-0fe630eb857a6ec83" # Update with the latest Amazon Linux 2 AMI
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   availability_zone      = "us-east-1a"
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Worker${count.index + 1}"
#   }
# }

# # Output Bastion Host Public IP
# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

# # Output Master Nodes Private IPs
# output "master_private_ips" {
#   value = aws_instance.master[*].private_ip
# }

# # Output Worker Nodes Private IPs
# output "worker_private_ips" {
#   value = aws_instance.worker[*].private_ip
# }



# provider "aws" {
#   region = "us-east-1"
# }

# # VPC
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# # Public Subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
# }

# # Private Subnet
# resource "aws_subnet" "private" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.2.0/24"
# }

# # Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id
# }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Security Groups
# resource "aws_security_group" "bastion_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.main.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group_rule" "private_ingress_ssh" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.bastion_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_api" {
#   type                     = "ingress"
#   from_port                = 6443
#   to_port                  = 6443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_kubelet" {
#   type                     = "ingress"
#   from_port                = 10250
#   to_port                  = 10250
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# # Bastion Host
# resource "aws_instance" "bastion" {
#   ami                    = var.ami_id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]

#   key_name = var.key_name

#   tags = {
#     Name = "BastionHost"
#   }
# }

# # Master Nodes
# resource "aws_instance" "master" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Master${count.index + 1}"
#   }
# }

# # Worker Nodes
# resource "aws_instance" "worker" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Worker${count.index + 1}"
#   }
# }

# # Output Bastion Host Public IP
# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

# # Output Master Nodes Private IPs
# output "master_private_ips" {
#   value = aws_instance.master[*].private_ip
# }

# # Output Worker Nodes Private IPs
# output "worker_private_ips" {
#   value = aws_instance.worker[*].private_ip
# }









# provider "aws" {
#   region = "us-east-1"
# }

# # VPC
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# # Public Subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
# }

# # Private Subnet
# resource "aws_subnet" "private" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.2.0/24"
# }

# # Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id
# }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Security Groups
# resource "aws_security_group" "bastion_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.main.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "nexus_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 8081
#     to_port     = 8081
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group_rule" "private_ingress_ssh" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.bastion_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_api" {
#   type                     = "ingress"
#   from_port                = 6443
#   to_port                  = 6443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# resource "aws_security_group_rule" "private_ingress_kubelet" {
#   type                     = "ingress"
#   from_port                = 10250
#   to_port                  = 10250
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.private_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# resource "aws_security_group_rule" "nexus_ingress_from_private_sg" {
#   type                     = "ingress"
#   from_port                = 8081
#   to_port                  = 8081
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.nexus_sg.id
#   source_security_group_id = aws_security_group.private_sg.id
# }

# # Bastion Host
# resource "aws_instance" "bastion" {
#   ami                    = var.ami_id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]

#   key_name = var.key_name

#   tags = {
#     Name = "BastionHost"
#   }
# }

# # Master Nodes
# resource "aws_instance" "master" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Master${count.index + 1}"
#   }
# }

# # Worker Nodes
# resource "aws_instance" "worker" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Worker${count.index + 1}"
#   }
# }

# # Nexus Server
# resource "aws_instance" "nexus" {
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.nexus_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 50 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "NexusServer"
#   }
# }

# # Output Bastion Host Public IP
# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

# # Output Master Nodes Private IPs
# output "master_private_ips" {
#   value = aws_instance.master[*].private_ip
# }

# # Output Worker Nodes Private IPs
# output "worker_private_ips" {
#   value = aws_instance.worker[*].private_ip
# }

# # Output Nexus Server Private IP
# output "nexus_private_ip" {
#   value = aws_instance.nexus.private_ip
# }







# provider "aws" {
#   region = "us-east-1"
# }

# # VPC
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# # Public Subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
# }

# # Private Subnet
# resource "aws_subnet" "private" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.2.0/24"
# }

# # Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id
# }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

# # Security Groups
# resource "aws_security_group" "bastion_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_subnet.private.cidr_block]  # Allow all traffic from the private subnet CIDR block
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_subnet.private.cidr_block]  # Allow all traffic to the private subnet CIDR block
#   }
# }

# resource "aws_security_group" "nexus_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 8081
#     to_port     = 8081
#     protocol    = "tcp"
#     cidr_blocks = [aws_subnet.private.cidr_block]  # Allow traffic from the private subnet CIDR block
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_subnet.private.cidr_block]  # Allow traffic to the private subnet CIDR block
#   }
# }

# # Bastion Host
# resource "aws_instance" "bastion" {
#   ami                    = var.ami_id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]

#   key_name = var.key_name

#   tags = {
#     Name = "BastionHost"
#   }
# }

# # Master Nodes
# resource "aws_instance" "master" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Master${count.index + 1}"
#   }
# }

# # Worker Nodes
# resource "aws_instance" "worker" {
#   count                  = 1
#   ami                    = var.ami_id
#   instance_type          = "t3.large"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.private_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 20 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "Worker${count.index + 1}"
#   }
# }

# # Nexus Server
# resource "aws_instance" "nexus" {
#   ami                    = var.ami_id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.nexus_sg.id]
#   # Adding EBS volume for storage
#   root_block_device {
#     volume_size = 10 # Size in GB
#     volume_type = "gp2" # General Purpose SSD (gp2)
#   }
#   key_name = var.key_name

#   tags = {
#     Name = "NexusServer"
#   }
# }

# # Output Bastion Host Public IP
# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

# # Output Master Nodes Private IPs
# output "master_private_ips" {
#   value = aws_instance.master[*].private_ip
# }

# # Output Worker Nodes Private IPs
# output "worker_private_ips" {
#   value = aws_instance.worker[*].private_ip
# }

# # Output Nexus Server Private IP
# output "nexus_private_ip" {
#   value = aws_instance.nexus.private_ip
# }



