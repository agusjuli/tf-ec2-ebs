# Use existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-02a88d80ac334f702" # Replace with your existing VPC ID
}

# Use existing public subnet
data "aws_subnet" "existing_subnet" {
  id = "subnet-02340127e4267789d" # Replace with your existing public subnet ID
}

# Create a security group to allow SSH access
resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from any IP (restrict this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2-instance" {
  ami                         = "ami-085ad6ae776d8f09c" # Replace with your desired AMI ID
  instance_type               = "t2.micro"              # Replace with your desired instance type
  subnet_id                   = data.aws_subnet.existing_subnet.id
  associate_public_ip_address = true
  key_name                    = "agusjuli-key-pair"         #Change to your keyname
  vpc_security_group_ids      = [aws_security_group.ssh.id] # Attach the SSH security group

  tags = {
    Name = "agusjuli-ec2-ebs"
  }
}

# Create a 1GB EBS volume in the same AZ as the subnet
resource "aws_ebs_volume" "agusjuli-ebs" {
  availability_zone = data.aws_subnet.existing_subnet.availability_zone
  size              = 1     # 1GB EBS volume
  type              = "gp3" # Set volume type to gp3
  iops              = 3000  # Set custom IOPS
  throughput        = 125   # Set custom throughput in MiB/s

  tags = {
    Name = "agusjuli-ebs"
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "agusjuli-ebs" {
  device_name = "/dev/sdb" # Replace with the desired device name
  volume_id   = aws_ebs_volume.agusjuli-ebs.id
  instance_id = aws_instance.ec2-instance.id
}