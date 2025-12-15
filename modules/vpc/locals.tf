################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Local Variables
################################################################################

locals {
  # Region
  region = data.aws_region.current.name

  # Availability Zones - use provided list or auto-select first N available AZs
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.azs_count)

  # Validate subnet counts don't exceed AZ count
  max_subnet_count = max(
    var.public_subnet_count,
    var.private_app_subnet_count,
    var.private_db_subnet_count,
    var.isolated_subnet_count
  )

  # CIDR Calculation Strategy:
  # - VPC CIDR is divided into 16 equal /20 blocks (tier blocks)
  # - Each tier (public, private-app, private-db, isolated) gets one /20 block
  # - Within each tier, subnets get /24 blocks (256 IPs each)
  # - This supports up to 16 subnets per tier across multiple AZs

  # Tier offsets for CIDR calculation
  public_tier_offset      = 0
  private_app_tier_offset = 1
  private_db_tier_offset  = 2
  isolated_tier_offset    = 3

  # Calculate tier blocks (/20 from /16 VPC CIDR)
  tier_newbits = 4

  public_tier_cidr      = cidrsubnet(var.vpc_cidr, local.tier_newbits, local.public_tier_offset)
  private_app_tier_cidr = cidrsubnet(var.vpc_cidr, local.tier_newbits, local.private_app_tier_offset)
  private_db_tier_cidr  = cidrsubnet(var.vpc_cidr, local.tier_newbits, local.private_db_tier_offset)
  isolated_tier_cidr    = cidrsubnet(var.vpc_cidr, local.tier_newbits, local.isolated_tier_offset)

  # Calculate individual subnet CIDRs
  public_subnet_cidrs = [
    for i in range(var.public_subnet_count) :
    cidrsubnet(local.public_tier_cidr, var.subnet_newbits - local.tier_newbits, i)
  ]

  private_app_subnet_cidrs = [
    for i in range(var.private_app_subnet_count) :
    cidrsubnet(local.private_app_tier_cidr, var.subnet_newbits - local.tier_newbits, i)
  ]

  private_db_subnet_cidrs = [
    for i in range(var.private_db_subnet_count) :
    cidrsubnet(local.private_db_tier_cidr, var.subnet_newbits - local.tier_newbits, i)
  ]

  isolated_subnet_cidrs = [
    for i in range(var.isolated_subnet_count) :
    cidrsubnet(local.isolated_tier_cidr, var.subnet_newbits - local.tier_newbits, i)
  ]

  # NAT Gateway configuration
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.public_subnet_count) : 0

  # VPC Flow Logs
  enable_flow_logs_cloudwatch = var.enable_flow_logs && contains(["cloud-watch-logs", "both"], var.flow_logs_destination_type)
  enable_flow_logs_s3         = var.enable_flow_logs && contains(["s3", "both"], var.flow_logs_destination_type)

  # VPC Endpoints - Interface endpoints require private subnets
  create_vpc_endpoints = var.private_app_subnet_count > 0

  # Interface endpoints list
  interface_endpoints = {
    ecr_api = {
      enabled      = var.enable_ecr_api_endpoint
      service_name = "ecr.api"
    }
    ecr_dkr = {
      enabled      = var.enable_ecr_dkr_endpoint
      service_name = "ecr.dkr"
    }
    logs = {
      enabled      = var.enable_logs_endpoint
      service_name = "logs"
    }
    ssm = {
      enabled      = var.enable_ssm_endpoint
      service_name = "ssm"
    }
    ec2messages = {
      enabled      = var.enable_ec2messages_endpoint
      service_name = "ec2messages"
    }
    ssmmessages = {
      enabled      = var.enable_ssmmessages_endpoint
      service_name = "ssmmessages"
    }
    sts = {
      enabled      = var.enable_sts_endpoint
      service_name = "sts"
    }
  }

  # Filter enabled interface endpoints
  enabled_interface_endpoints = {
    for k, v in local.interface_endpoints : k => v if v.enabled && local.create_vpc_endpoints
  }

  # EKS Tags
  eks_public_subnet_tags = var.enable_eks_tags && var.eks_cluster_name != "" ? {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  } : {}

  eks_private_subnet_tags = var.enable_eks_tags && var.eks_cluster_name != "" ? {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  } : {}

  # Common tags applied to all resources
  common_tags = merge(
    {
      Name        = var.vpc_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "vpc"
    },
    var.tags
  )

  # VPC-specific tags
  vpc_tags_merged = merge(
    local.common_tags,
    {
      Name = var.vpc_name
    },
    var.vpc_tags
  )
}
