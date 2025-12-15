################################################################################
# VPC Configuration
################################################################################

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. Must be a valid private IPv4 range."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.)", var.vpc_cidr))
    error_message = "VPC CIDR should use private IP ranges (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)."
  }
}

variable "vpc_name" {
  description = "Name of the VPC. Used for resource naming and tagging."
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0 && length(var.vpc_name) <= 64
    error_message = "VPC name must be between 1 and 64 characters."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC. Required for VPC endpoints and EKS."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC. Should always be true for production workloads."
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 support (dual-stack VPC). Assigns Amazon-provided IPv6 CIDR block."
  type        = bool
  default     = false
}

################################################################################
# Availability Zones
################################################################################

variable "availability_zones" {
  description = "List of availability zones to use. If empty, automatically selects first N available AZs based on subnet counts."
  type        = list(string)
  default     = []
}

variable "azs_count" {
  description = "Number of availability zones to use when availability_zones is empty. Defaults to 3 for production resilience."
  type        = number
  default     = 3

  validation {
    condition     = var.azs_count >= 2 && var.azs_count <= 6
    error_message = "AZ count must be between 2 and 6 for production workloads."
  }
}

################################################################################
# Subnet Configuration
################################################################################

variable "public_subnet_count" {
  description = "Number of public subnets to create (one per AZ). Set to 0 to disable public subnets."
  type        = number
  default     = 3

  validation {
    condition     = var.public_subnet_count >= 0 && var.public_subnet_count <= 6
    error_message = "Public subnet count must be between 0 and 6."
  }
}

variable "private_app_subnet_count" {
  description = "Number of private application subnets to create (one per AZ). For EKS nodes, ECS tasks, EC2 instances."
  type        = number
  default     = 3

  validation {
    condition     = var.private_app_subnet_count >= 0 && var.private_app_subnet_count <= 6
    error_message = "Private app subnet count must be between 0 and 6."
  }
}

variable "private_db_subnet_count" {
  description = "Number of private database subnets to create (one per AZ). For RDS, ElastiCache, Redshift."
  type        = number
  default     = 3

  validation {
    condition     = var.private_db_subnet_count >= 0 && var.private_db_subnet_count <= 6
    error_message = "Private DB subnet count must be between 0 and 6."
  }
}

variable "isolated_subnet_count" {
  description = "Number of isolated subnets to create (one per AZ). No internet access, VPC-local only."
  type        = number
  default     = 0

  validation {
    condition     = var.isolated_subnet_count >= 0 && var.isolated_subnet_count <= 6
    error_message = "Isolated subnet count must be between 0 and 6."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to add to VPC CIDR for subnet sizing. Default 8 creates /24 subnets from /16 VPC."
  type        = number
  default     = 8

  validation {
    condition     = var.subnet_newbits >= 4 && var.subnet_newbits <= 12
    error_message = "Subnet newbits must be between 4 and 12."
  }
}

################################################################################
# Internet Gateway & NAT
################################################################################

variable "enable_internet_gateway" {
  description = "Create an Internet Gateway. Required for public subnets and NAT gateways."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s) for private subnet internet access. Required for private subnets to reach internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost-optimized). False creates one NAT per AZ (production resilience)."
  type        = bool
  default     = false
}

################################################################################
# VPC Flow Logs
################################################################################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network traffic monitoring and security analysis."
  type        = bool
  default     = true
}

variable "flow_logs_destination_type" {
  description = "Destination type for VPC Flow Logs. Valid values: 'cloud-watch-logs', 's3', 'both'."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3", "both"], var.flow_logs_destination_type)
    error_message = "Flow logs destination type must be 'cloud-watch-logs', 's3', or 'both'."
  }
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in VPC Flow Logs. Valid values: 'ACCEPT', 'REJECT', 'ALL'."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be 'ACCEPT', 'REJECT', or 'ALL'."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period in days for VPC Flow Logs. 0 means never expire."
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_retention_days)
    error_message = "Flow logs retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_logs_s3_bucket_arn" {
  description = "ARN of S3 bucket for VPC Flow Logs. Required when flow_logs_destination_type is 's3' or 'both'."
  type        = string
  default     = ""
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch Logs. If not provided, uses AWS managed key."
  type        = string
  default     = ""
}

################################################################################
# VPC Endpoints
################################################################################

variable "enable_s3_endpoint" {
  description = "Create VPC Gateway Endpoint for S3. Recommended for production (no cost, improves performance)."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create VPC Gateway Endpoint for DynamoDB. Recommended if using DynamoDB (no cost)."
  type        = bool
  default     = false
}

variable "enable_ecr_api_endpoint" {
  description = "Create VPC Interface Endpoint for ECR API. Required for private EKS/ECS clusters (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_ecr_dkr_endpoint" {
  description = "Create VPC Interface Endpoint for ECR Docker. Required for private EKS/ECS clusters (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "Create VPC Interface Endpoint for CloudWatch Logs. Recommended for private subnets (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_ssm_endpoint" {
  description = "Create VPC Interface Endpoint for SSM. Required for Session Manager without internet (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_ec2messages_endpoint" {
  description = "Create VPC Interface Endpoint for EC2 Messages. Required for SSM Session Manager (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_ssmmessages_endpoint" {
  description = "Create VPC Interface Endpoint for SSM Messages. Required for SSM Session Manager (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "enable_sts_endpoint" {
  description = "Create VPC Interface Endpoint for STS. Recommended for IRSA/Pod Identity in private EKS (~$7/month per AZ)."
  type        = bool
  default     = false
}

variable "vpc_endpoint_security_group_ids" {
  description = "Security group IDs to attach to VPC Interface Endpoints. If empty, creates a default security group."
  type        = list(string)
  default     = []
}

################################################################################
# EKS Integration
################################################################################

variable "enable_eks_tags" {
  description = "Add Kubernetes-specific tags to subnets for EKS cluster integration."
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster for subnet tagging. Required when enable_eks_tags is true."
  type        = string
  default     = ""
}

################################################################################
# Tagging
################################################################################

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Used for tagging and resource naming."
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags specific to the VPC resource."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets."
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_tags" {
  description = "Additional tags for private application subnets."
  type        = map(string)
  default     = {}
}

variable "private_db_subnet_tags" {
  description = "Additional tags for private database subnets."
  type        = map(string)
  default     = {}
}

variable "isolated_subnet_tags" {
  description = "Additional tags for isolated subnets."
  type        = map(string)
  default     = {}
}
