################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block of the VPC"
  value       = var.enable_ipv6 ? aws_vpc.main.ipv6_cidr_block : null
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with the VPC"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group (not recommended for use)"
  value       = aws_vpc.main.default_security_group_id
}

################################################################################
# Availability Zones
################################################################################

output "availability_zones" {
  description = "List of availability zones used by the VPC"
  value       = local.azs
}

output "azs_count" {
  description = "Number of availability zones used"
  value       = length(local.azs)
}

################################################################################
# Public Subnet Outputs
################################################################################

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnets_by_az" {
  description = "Map of availability zone to public subnet ID"
  value = {
    for idx, az in local.azs :
    az => idx < var.public_subnet_count ? aws_subnet.public[idx].id : null
  }
}

################################################################################
# Private Application Subnet Outputs
################################################################################

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_app_subnet_arns" {
  description = "List of private application subnet ARNs"
  value       = aws_subnet.private_app[*].arn
}

output "private_app_subnet_cidrs" {
  description = "List of private application subnet CIDR blocks"
  value       = aws_subnet.private_app[*].cidr_block
}

output "private_app_subnets_by_az" {
  description = "Map of availability zone to private application subnet ID"
  value = {
    for idx, az in local.azs :
    az => idx < var.private_app_subnet_count ? aws_subnet.private_app[idx].id : null
  }
}

################################################################################
# Private Database Subnet Outputs
################################################################################

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = aws_subnet.private_db[*].id
}

output "private_db_subnet_arns" {
  description = "List of private database subnet ARNs"
  value       = aws_subnet.private_db[*].arn
}

output "private_db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks"
  value       = aws_subnet.private_db[*].cidr_block
}

output "private_db_subnets_by_az" {
  description = "Map of availability zone to private database subnet ID"
  value = {
    for idx, az in local.azs :
    az => idx < var.private_db_subnet_count ? aws_subnet.private_db[idx].id : null
  }
}

################################################################################
# Isolated Subnet Outputs
################################################################################

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs"
  value       = aws_subnet.isolated[*].id
}

output "isolated_subnet_arns" {
  description = "List of isolated subnet ARNs"
  value       = aws_subnet.isolated[*].arn
}

output "isolated_subnet_cidrs" {
  description = "List of isolated subnet CIDR blocks"
  value       = aws_subnet.isolated[*].cidr_block
}

output "isolated_subnets_by_az" {
  description = "Map of availability zone to isolated subnet ID"
  value = {
    for idx, az in local.azs :
    az => idx < var.isolated_subnet_count ? aws_subnet.isolated[idx].id : null
  }
}

################################################################################
# Route Table Outputs
################################################################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.public_subnet_count > 0 ? aws_route_table.public[0].id : null
}

output "private_app_route_table_ids" {
  description = "List of private application route table IDs"
  value       = aws_route_table.private_app[*].id
}

output "private_db_route_table_ids" {
  description = "List of private database route table IDs"
  value       = aws_route_table.private_db[*].id
}

output "isolated_route_table_ids" {
  description = "List of isolated route table IDs"
  value       = aws_route_table.isolated[*].id
}

################################################################################
# Internet Gateway Outputs
################################################################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.enable_internet_gateway ? aws_internet_gateway.main[0].id : null
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = var.enable_internet_gateway ? aws_internet_gateway.main[0].arn : null
}

################################################################################
# NAT Gateway Outputs
################################################################################

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of Elastic IP allocation IDs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

output "nat_gateways_by_az" {
  description = "Map of availability zone to NAT Gateway ID"
  value = {
    for idx, az in local.azs :
    az => idx < local.nat_gateway_count ? aws_nat_gateway.main[idx].id : null
  }
}

################################################################################
# VPC Flow Logs Outputs
################################################################################

output "flow_logs_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = local.enable_flow_logs_cloudwatch ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = local.enable_flow_logs_cloudwatch ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "flow_logs_iam_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = local.enable_flow_logs_cloudwatch ? aws_iam_role.flow_logs[0].arn : null
}

################################################################################
# VPC Endpoint Outputs
################################################################################

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_s3_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC Gateway Endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].prefix_list_id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC Gateway Endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoint_dynamodb_prefix_list_id" {
  description = "Prefix list ID of the DynamoDB VPC Gateway Endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].prefix_list_id : null
}

output "vpc_endpoint_interface_ids" {
  description = "Map of interface VPC endpoint names to their IDs"
  value = {
    for k, v in aws_vpc_endpoint.interface : k => v.id
  }
}

output "vpc_endpoint_interface_dns_entries" {
  description = "Map of interface VPC endpoint names to their DNS entries"
  value = {
    for k, v in aws_vpc_endpoint.interface : k => v.dns_entry
  }
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC Interface Endpoints"
  value       = length(local.enabled_interface_endpoints) > 0 && length(var.vpc_endpoint_security_group_ids) == 0 ? aws_security_group.vpc_endpoints[0].id : null
}

################################################################################
# Computed Outputs
################################################################################

output "region" {
  description = "AWS region where the VPC is deployed"
  value       = local.region
}

output "nat_gateway_strategy" {
  description = "NAT Gateway deployment strategy (single or multi-az)"
  value       = var.single_nat_gateway ? "single" : "multi-az"
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways deployed"
  value       = local.nat_gateway_count
}
