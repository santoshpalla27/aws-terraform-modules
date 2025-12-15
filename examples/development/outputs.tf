################################################################################
# Outputs for Production VPC Example
################################################################################

################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "region" {
  description = "AWS region where the VPC is deployed"
  value       = module.vpc.region
}

output "availability_zones" {
  description = "List of availability zones used by the VPC"
  value       = module.vpc.availability_zones
}

################################################################################
# Subnet Outputs
################################################################################

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs"
  value       = module.vpc.isolated_subnet_ids
}

# Subnet maps by AZ (useful for AZ-specific resources)
output "public_subnets_by_az" {
  description = "Map of availability zone to public subnet ID"
  value       = module.vpc.public_subnets_by_az
}

output "private_app_subnets_by_az" {
  description = "Map of availability zone to private application subnet ID"
  value       = module.vpc.private_app_subnets_by_az
}

output "private_db_subnets_by_az" {
  description = "Map of availability zone to private database subnet ID"
  value       = module.vpc.private_db_subnets_by_az
}

################################################################################
# NAT Gateway Outputs
################################################################################

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs associated with NAT Gateways"
  value       = module.vpc.nat_gateway_public_ips
}

output "nat_gateway_strategy" {
  description = "NAT Gateway deployment strategy (single or multi-az)"
  value       = module.vpc.nat_gateway_strategy
}

################################################################################
# Internet Gateway Outputs
################################################################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

################################################################################
# Route Table Outputs
################################################################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "List of private application route table IDs"
  value       = module.vpc.private_app_route_table_ids
}

output "private_db_route_table_ids" {
  description = "List of private database route table IDs"
  value       = module.vpc.private_db_route_table_ids
}

################################################################################
# VPC Endpoint Outputs
################################################################################

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = module.vpc.vpc_endpoint_s3_id
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC Gateway Endpoint"
  value       = module.vpc.vpc_endpoint_dynamodb_id
}

output "vpc_endpoint_interface_ids" {
  description = "Map of interface VPC endpoint names to their IDs"
  value       = module.vpc.vpc_endpoint_interface_ids
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC Interface Endpoints"
  value       = module.vpc.vpc_endpoints_security_group_id
}

################################################################################
# VPC Flow Logs Outputs
################################################################################

output "flow_logs_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = module.vpc.flow_logs_cloudwatch_log_group_name
}

output "flow_logs_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = module.vpc.flow_logs_cloudwatch_log_group_arn
}

################################################################################
# Optional: Security Group Outputs
# Uncomment if you created custom security groups in main.tf
################################################################################

# output "alb_security_group_id" {
#   description = "ID of the ALB security group"
#   value       = aws_security_group.alb.id
# }

# output "app_security_group_id" {
#   description = "ID of the application security group"
#   value       = aws_security_group.app.id
# }

# output "db_security_group_id" {
#   description = "ID of the database security group"
#   value       = aws_security_group.db.id
# }

################################################################################
# Optional: Subnet Group Outputs
# Uncomment if you created subnet groups in main.tf
################################################################################

# output "db_subnet_group_name" {
#   description = "Name of the RDS subnet group"
#   value       = aws_db_subnet_group.main.name
# }

# output "elasticache_subnet_group_name" {
#   description = "Name of the ElastiCache subnet group"
#   value       = aws_elasticache_subnet_group.main.name
# }

# output "redshift_subnet_group_name" {
#   description = "Name of the Redshift subnet group"
#   value       = aws_redshift_subnet_group.main.name
# }

################################################################################
# Optional: Transit Gateway Outputs
# Uncomment if you created Transit Gateway attachment in main.tf
################################################################################

# output "transit_gateway_attachment_id" {
#   description = "ID of the Transit Gateway VPC attachment"
#   value       = aws_ec2_transit_gateway_vpc_attachment.main.id
# }

################################################################################
# Optional: VPC Peering Outputs
# Uncomment if you created VPC peering connection in main.tf
################################################################################

# output "vpc_peering_connection_id" {
#   description = "ID of the VPC peering connection"
#   value       = aws_vpc_peering_connection.peer.id
# }
