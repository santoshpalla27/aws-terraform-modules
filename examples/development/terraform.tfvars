################################################################################
# Development VPC Configuration Example (Cost-Optimized)
# This file demonstrates a cost-optimized configuration for dev/test environments
################################################################################

# Required Variables
vpc_name    = "dev-vpc"
vpc_cidr    = "10.0.0.0/16"
environment = "dev"

################################################################################
# Availability Zones Configuration (Reduced for Cost Savings)
################################################################################

azs_count = 2 # Use 2 AZs instead of 3 to reduce NAT costs

################################################################################
# DNS Configuration
################################################################################

enable_dns_hostnames = true
enable_dns_support   = true

################################################################################
# Subnet Configuration
################################################################################

public_subnet_count      = 2 # Match AZ count
private_app_subnet_count = 2 # Match AZ count
private_db_subnet_count  = 2 # Match AZ count
isolated_subnet_count    = 0 # Not needed for dev

subnet_newbits = 8

################################################################################
# Internet Gateway & NAT Configuration (Cost-Optimized)
################################################################################

enable_internet_gateway = true

# NAT Gateway - SINGLE NAT for cost savings
enable_nat_gateway = true
single_nat_gateway = true # Cost: ~$32/month vs ~$64/month for multi-AZ

################################################################################
# VPC Flow Logs Configuration (Reduced Retention)
################################################################################

enable_flow_logs = true

# Use CloudWatch with shorter retention for cost savings
flow_logs_destination_type = "cloud-watch-logs"
flow_logs_traffic_type     = "ALL"
flow_logs_retention_days   = 7 # 7 days instead of 30 for cost savings

# Alternative: Use S3 for even lower costs
# flow_logs_destination_type = "s3"
# flow_logs_s3_bucket_arn    = "arn:aws:s3:::my-dev-flow-logs-bucket"

################################################################################
# VPC Endpoints - Minimal Configuration (Cost-Optimized)
################################################################################

# Gateway Endpoints (Free) - Always enable
enable_s3_endpoint       = true
enable_dynamodb_endpoint = false # Only if using DynamoDB

# Interface Endpoints - Disabled for cost savings
# Enable only if absolutely required for your dev environment
enable_ecr_api_endpoint     = false # Enable if using private ECR
enable_ecr_dkr_endpoint     = false # Enable if using private ECR
enable_logs_endpoint        = false # Not critical for dev
enable_ssm_endpoint         = false # Not critical for dev
enable_ec2messages_endpoint = false # Not critical for dev
enable_ssmmessages_endpoint = false # Not critical for dev
enable_sts_endpoint         = false # Not critical for dev

# To enable interface endpoints for testing EKS/ECS, uncomment:
# enable_ecr_api_endpoint = true
# enable_ecr_dkr_endpoint = true
# enable_sts_endpoint     = true

################################################################################
# EKS Integration (Optional)
################################################################################

# Enable if testing EKS in dev environment
enable_eks_tags  = false
eks_cluster_name = ""

# To enable EKS tags, uncomment:
# enable_eks_tags  = true
# eks_cluster_name = "dev-eks-cluster"

################################################################################
# Tagging Strategy
################################################################################

tags = {
  Project     = "my-app"
  Owner       = "dev-team"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CostCenter  = "development"
}

vpc_tags = {
  Description = "Development VPC for testing"
}

public_subnet_tags = {
  Tier = "Public"
}

private_app_subnet_tags = {
  Tier = "PrivateApp"
}

private_db_subnet_tags = {
  Tier = "PrivateDB"
}

################################################################################
# Cost Estimate for This Configuration
################################################################################

# Monthly Cost Breakdown (approximate):
# - NAT Gateway (single):           ~$32
# - Flow Logs (CloudWatch, 7 days): ~$15
# - Data Transfer:                  ~$20-50
# ----------------------------------------
# Total:                            ~$67-97/month
#
# Cost Savings vs Production:
# - Single NAT vs Multi-AZ:         ~$64 saved
# - No Interface Endpoints:         ~$147 saved
# - Shorter log retention:          ~$30 saved
# - 2 AZs vs 3 AZs:                ~$32 saved (one less NAT)
# ----------------------------------------
# Total Savings:                    ~$273/month (73% reduction)
#
# When to Upgrade to Production Config:
# 1. Moving to staging/production environment
# 2. Need high availability (multi-AZ NAT)
# 3. Running private EKS/ECS clusters (need VPC endpoints)
# 4. Compliance requirements (longer log retention)
