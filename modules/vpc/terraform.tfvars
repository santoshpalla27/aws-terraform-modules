################################################################################
# Required Variables
################################################################################

# VPC Configuration
vpc_name    = "my-vpc"
vpc_cidr    = "10.0.0.0/16"
environment = "dev"

################################################################################
# Availability Zones (Optional - auto-selects if not specified)
################################################################################

# availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
azs_count = 3

################################################################################
# Subnet Configuration
################################################################################

public_subnet_count      = 3
private_app_subnet_count = 3
private_db_subnet_count  = 3
isolated_subnet_count    = 3

# Subnet sizing (default 8 creates /24 subnets from /16 VPC)
subnet_newbits = 8

################################################################################
# Internet Gateway & NAT
################################################################################

enable_internet_gateway = true
enable_nat_gateway      = true
single_nat_gateway      = false # Set to true for cost savings in dev/test

################################################################################
# VPC DNS Settings
################################################################################

enable_dns_hostnames = true
enable_dns_support   = true
enable_ipv6          = false

################################################################################
# VPC Flow Logs
################################################################################

enable_flow_logs           = true
flow_logs_destination_type = "cloud-watch-logs"
flow_logs_traffic_type     = "ALL"
flow_logs_retention_days   = 7

# Optional: S3 bucket ARN for flow logs (required if destination_type is "s3" or "both")
# flow_logs_s3_bucket_arn = "arn:aws:s3:::my-flow-logs-bucket"

# Optional: KMS key for CloudWatch Logs encryption
# flow_logs_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

################################################################################
# VPC Endpoints
################################################################################

# Gateway Endpoints (no cost)
enable_s3_endpoint       = true
enable_dynamodb_endpoint = false

# Interface Endpoints (~$7/month per AZ)
enable_ecr_api_endpoint     = false
enable_ecr_dkr_endpoint     = false
enable_logs_endpoint        = false
enable_ssm_endpoint         = false
enable_ec2messages_endpoint = false
enable_ssmmessages_endpoint = false
enable_sts_endpoint         = false

# Optional: Custom security groups for VPC endpoints
# vpc_endpoint_security_group_ids = ["sg-12345678"]

################################################################################
# EKS Integration (Optional)
################################################################################

enable_eks_tags = false
# eks_cluster_name = "my-eks-cluster"

################################################################################
# Additional Tags
################################################################################

tags = {
  Project    = "MyProject"
  ManagedBy  = "Terraform"
  CostCenter = "Engineering"
}

# Optional: Resource-specific tags
vpc_tags = {
  Description = "Main VPC for dev environment"
}

public_subnet_tags = {
  Tier = "Public"
}

private_app_subnet_tags = {
  Tier = "Application"
}

private_db_subnet_tags = {
  Tier = "Database"
}

isolated_subnet_tags = {
  Tier = "Isolated"
}
