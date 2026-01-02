provider "aws" {
  region = "us-west-2"  
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for wordpress,python and SSH"

  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["23.241.194.129/32"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_instance" "ec2" {
  ami                    = "ami-00f46ccd1cbfb363e" # ubuntu server (Oregon)
  instance_type          = "c7i-flex.large"
  key_name               = "EC2_Keypair"         # .pem extension will be added auto
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "Jenkins-Flask-EC2"
  }
}

