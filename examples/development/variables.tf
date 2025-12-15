################################################################################
# Variables for Production VPC Example
################################################################################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "my-application"
}

################################################################################
# VPC Core Variables
################################################################################

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 support (dual-stack VPC)"
  type        = bool
  default     = false
}

################################################################################
# Availability Zones
################################################################################

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "azs_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

################################################################################
# Subnet Configuration
################################################################################

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "private_app_subnet_count" {
  description = "Number of private application subnets to create"
  type        = number
  default     = 3
}

variable "private_db_subnet_count" {
  description = "Number of private database subnets to create"
  type        = number
  default     = 3
}

variable "isolated_subnet_count" {
  description = "Number of isolated subnets to create"
  type        = number
  default     = 0
}

variable "subnet_newbits" {
  description = "Number of additional bits for subnet sizing"
  type        = number
  default     = 8
}

################################################################################
# Internet Gateway & NAT
################################################################################

variable "enable_internet_gateway" {
  description = "Create an Internet Gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost-optimized)"
  type        = bool
  default     = false
}

################################################################################
# VPC Flow Logs
################################################################################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_destination_type" {
  description = "Destination type for VPC Flow Logs"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in VPC Flow Logs"
  type        = string
  default     = "ALL"
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
}

variable "flow_logs_s3_bucket_arn" {
  description = "ARN of S3 bucket for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch Logs"
  type        = string
  default     = ""
}

################################################################################
# VPC Endpoints
################################################################################

variable "enable_s3_endpoint" {
  description = "Create VPC Gateway Endpoint for S3"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create VPC Gateway Endpoint for DynamoDB"
  type        = bool
  default     = false
}

variable "enable_ecr_api_endpoint" {
  description = "Create VPC Interface Endpoint for ECR API"
  type        = bool
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  description = "Create VPC Interface Endpoint for ECR Docker"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Create VPC Interface Endpoint for CloudWatch Logs"
  type        = bool
  default     = true
}

variable "enable_ssm_endpoint" {
  description = "Create VPC Interface Endpoint for SSM"
  type        = bool
  default     = true
}

variable "enable_ec2messages_endpoint" {
  description = "Create VPC Interface Endpoint for EC2 Messages"
  type        = bool
  default     = true
}

variable "enable_ssmmessages_endpoint" {
  description = "Create VPC Interface Endpoint for SSM Messages"
  type        = bool
  default     = true
}

variable "enable_sts_endpoint" {
  description = "Create VPC Interface Endpoint for STS"
  type        = bool
  default     = true
}

################################################################################
# EKS Integration
################################################################################

variable "enable_eks_tags" {
  description = "Add Kubernetes-specific tags to subnets"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster for subnet tagging"
  type        = string
  default     = ""
}

################################################################################
# Tagging
################################################################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags specific to the VPC resource"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_tags" {
  description = "Additional tags for private application subnets"
  type        = map(string)
  default     = {}
}

variable "private_db_subnet_tags" {
  description = "Additional tags for private database subnets"
  type        = map(string)
  default     = {}
}

variable "isolated_subnet_tags" {
  description = "Additional tags for isolated subnets"
  type        = map(string)
  default     = {}
}

################################################################################
# Optional: Transit Gateway
################################################################################

variable "transit_gateway_id" {
  description = "ID of Transit Gateway to attach VPC to"
  type        = string
  default     = ""
}

################################################################################
# Optional: VPC Peering
################################################################################

variable "peer_vpc_id" {
  description = "ID of VPC to peer with"
  type        = string
  default     = ""
}

variable "peer_vpc_name" {
  description = "Name of VPC to peer with"
  type        = string
  default     = ""
}

variable "peer_vpc_cidr" {
  description = "CIDR block of VPC to peer with"
  type        = string
  default     = ""
}
