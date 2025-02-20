provider "aws" {
  region = "us-east-1"
}

# Criar um par de chaves SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Criar Grupo de Segurança para permitir acesso SSH e HTTP
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Permitir acesso SSH e HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Liberado para qualquer IP (para fins de teste)
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Criar instância EC2
resource "aws_instance" "web" {
  ami             = "ami-0c55b159cbfafe1f0"  # Ubuntu Server (mudar conforme a região)
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer_key.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "MeuServidorEC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2
              echo "<h1>Servidor EC2 Implantado com Terraform 🚀</h1>" | sudo tee /var/www/html/index.html
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF
}

# Criar um Elastic IP para a instância EC2
resource "aws_eip" "ec2_eip" {
  instance = aws_instance.web.id
}

# Salvar a chave privada localmente (NÃO SUBIR PARA O GITHUB)
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "key.pem"
}