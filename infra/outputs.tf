output "public_ip" {
  description = "IP Público da Instância EC2"
  value       = aws_eip.ec2_eip.public_ip
}