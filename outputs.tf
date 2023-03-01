#Outputs
output "hoh-vpc" {
  description = "HoH VPC1"
  value       = aws_vpc.hoh-app-vpc
}

output "hohvpcsubnetprod" {
  description = "HoH VPC1 Subnet Production"
  value       = aws_subnet.SubnetProd
}

output "hohvpvsubnetdev" {
  description = "HoH VPC1 Subnet Development"
  value       = aws_subnet.SubnetDev
}