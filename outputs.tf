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
