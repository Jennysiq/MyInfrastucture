output "ids_t2" {
  description = "List of IDs of t2-type instances"
  value       = module.ec2_with_t2_unlimited.id
}

output "t2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_with_t2_unlimited.id[0]
}

output "credit_specification_t2_unlimited" {
  description = "Credit specification of t2-type EC2 instance"
  value       = module.ec2_with_t2_unlimited.credit_specification
}

############################ADDED#######################
  
output "ec2-public-dns" {
    value = aws_instance.public-ec2.public_dns
}

output "ec2-public-ip" {
    value = aws_instance.public-ec2.public_ip
}

output "ec2-public-private-dns" {
    value = aws_instance.public-ec2.private_dns
}

output "ec2-public-private-ip" {
    value = aws_instance.public-ec2.private_ip
}

output "db-address" {
    value = aws_db_instance.default.address
}

output "db-arn" {
    value = aws_db_instance.default.arn
}

output "db-domain" {
    value = aws_db_instance.default.domain
}

output "db-id" {
    value = aws_db_instance.default.id
}

output "db-name" {
    value = aws_db_instance.default.name
}

output "db-port" {
    value = aws_db_instance.default.port
}
