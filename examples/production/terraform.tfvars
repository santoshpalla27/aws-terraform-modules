################################################################################
# Production VPC Configuration Example
# This file demonstrates all available configuration options for the VPC module
################################################################################

# Required Variables
vpc_name    = "prod-vpc"
vpc_cidr    = "10.0.0.0/16"
environment = "prod"

################################################################################
# Availability Zones Configuration
################################################################################

# Option 1: Auto-select first N available AZs (recommended)
azs_count = 3

# Option 2: Explicitly specify AZs (uncomment to use)
# availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

################################################################################
# DNS Configuration
################################################################################

enable_dns_hostnames = true # Required for VPC endpoints and EKS
enable_dns_support   = true # Should always be true

################################################################################
# IPv6 Configuration
################################################################################

# Enable IPv6 dual-stack VPC (uncomment to enable)
# enable_ipv6 = true

################################################################################
# Subnet Configuration
################################################################################

# Number of subnets per tier (one per AZ)
public_subnet_count      = 3 # Internet-facing resources (ALB, NAT)
private_app_subnet_count = 3 # Application workloads (EKS, ECS, EC2)
private_db_subnet_count  = 3 # Database instances (RDS, ElastiCache)
isolated_subnet_count    = 0 # Air-gapped workloads (set to 3 if needed)

# Subnet sizing (default creates /24 subnets from /16 VPC)
subnet_newbits = 8

################################################################################
# Internet Gateway & NAT Configuration
################################################################################

enable_internet_gateway = true

# NAT Gateway configuration
enable_nat_gateway = true

# NAT Strategy:
# - false (default): Multi-AZ NAT - one NAT per AZ (~$96/month for 3 AZs)
#   Recommended for production (high availability, no single point of failure)
# - true: Single NAT - one NAT in first AZ (~$32/month)
#   Recommended for dev/test only (cost-optimized, but single point of failure)
single_nat_gateway = false

################################################################################
# VPC Flow Logs Configuration
################################################################################

enable_flow_logs = true

# Flow logs destination type:
# - "cloud-watch-logs": Real-time analysis, CloudWatch Insights integration
# - "s3": Long-term storage, cost-effective archival
# - "both": Send to both CloudWatch and S3
flow_logs_destination_type = "cloud-watch-logs"

# Traffic type to capture
# - "ALL": Capture all traffic (recommended)
# - "ACCEPT": Only accepted traffic
# - "REJECT": Only rejected traffic
flow_logs_traffic_type = "ALL"

# CloudWatch Logs retention (days)
# Valid values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, etc.
flow_logs_retention_days = 30

# S3 bucket ARN for flow logs (required if destination_type is "s3" or "both")
# flow_logs_s3_bucket_arn = "arn:aws:s3:::my-vpc-flow-logs-bucket"

# KMS key for CloudWatch Logs encryption (optional, uses AWS managed key if not provided)
# flow_logs_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

################################################################################
# VPC Endpoints - Gateway (Free)
################################################################################

# S3 Gateway Endpoint (recommended, no cost)
enable_s3_endpoint = true

# DynamoDB Gateway Endpoint (enable if using DynamoDB, no cost)
enable_dynamodb_endpoint = false

################################################################################
# VPC Endpoints - Interface (~$7/month per AZ each)
################################################################################

# ECR Endpoints (required for private EKS/ECS clusters)
enable_ecr_api_endpoint = true # ECR API (~$21/month for 3 AZs)
enable_ecr_dkr_endpoint = true # ECR Docker (~$21/month for 3 AZs)

# CloudWatch Logs Endpoint (recommended for private subnets)
enable_logs_endpoint = true # ~$21/month for 3 AZs

# SSM Endpoints (required for Session Manager without internet)
enable_ssm_endpoint         = true # SSM (~$21/month for 3 AZs)
enable_ec2messages_endpoint = true # EC2 Messages (~$21/month for 3 AZs)
enable_ssmmessages_endpoint = true # SSM Messages (~$21/month for 3 AZs)

# STS Endpoint (recommended for IRSA/Pod Identity in private EKS)
enable_sts_endpoint = true # ~$21/month for 3 AZs

# Custom security group IDs for VPC endpoints (optional)
# If not provided, module creates a default security group allowing HTTPS from VPC CIDR
# vpc_endpoint_security_group_ids = ["sg-0123456789abcdef0"]

################################################################################
# EKS Integration
################################################################################

# Enable Kubernetes-specific subnet tags for EKS
enable_eks_tags = true

# EKS cluster name (required when enable_eks_tags is true)
eks_cluster_name = "my-eks-cluster"

################################################################################
# Tagging Strategy
################################################################################

# Common tags applied to all resources
tags = {
  Project     = "my-application"
  Owner       = "platform-team"
  CostCenter  = "engineering"
  ManagedBy   = "Terraform"
  Environment = "prod"
  Compliance  = "pci-dss"
}

# VPC-specific tags
vpc_tags = {
  Description = "Production VPC for my-application"
}

# Subnet-specific tags (optional)
public_subnet_tags = {
  Tier = "Public"
  Type = "Internet-Facing"
}

private_app_subnet_tags = {
  Tier = "PrivateApp"
  Type = "Application"
}

private_db_subnet_tags = {
  Tier = "PrivateDB"
  Type = "Database"
}

# isolated_subnet_tags = {
#   Tier = "Isolated"
#   Type = "AirGapped"
# }

################################################################################
# Cost Estimate for This Configuration
################################################################################

# Monthly Cost Breakdown (approximate):
# - NAT Gateways (3 AZs):           ~$96
# - Interface Endpoints (7 × 3 AZs): ~$147
# - Flow Logs (CloudWatch):          ~$50
# - Data Transfer:                   ~$100-200
# ----------------------------------------
# Total:                             ~$393-493/month
#
# Cost Optimization Options:
# 1. Use single_nat_gateway = true for dev/test (~$64 savings)
# 2. Disable unused VPC endpoints (~$21 per endpoint per month)
# 3. Use S3 for flow logs instead of CloudWatch (~$27 savings)
# 4. Reduce flow_logs_retention_days to 7 (~$30 savings)
