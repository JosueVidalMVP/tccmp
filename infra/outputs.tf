# ID da VPC Criada
output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.my_vpc.id
}