################################################################################
# Production VPC Example
# This example demonstrates how to use the VPC module with production settings
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "vpc/prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  #   kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  # }
}

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  # Required variables
  vpc_name    = var.vpc_name
  vpc_cidr    = var.vpc_cidr
  environment = var.environment

  # Availability Zones
  azs_count = var.azs_count
  # availability_zones = var.availability_zones  # Uncomment to use explicit AZs

  # DNS Configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # IPv6 Configuration
  # enable_ipv6 = var.enable_ipv6

  # Subnet Configuration
  public_subnet_count      = var.public_subnet_count
  private_app_subnet_count = var.private_app_subnet_count
  private_db_subnet_count  = var.private_db_subnet_count
  isolated_subnet_count    = var.isolated_subnet_count
  subnet_newbits           = var.subnet_newbits

  # Internet Gateway & NAT
  enable_internet_gateway = var.enable_internet_gateway
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway

  # VPC Flow Logs
  enable_flow_logs           = var.enable_flow_logs
  flow_logs_destination_type = var.flow_logs_destination_type
  flow_logs_traffic_type     = var.flow_logs_traffic_type
  flow_logs_retention_days   = var.flow_logs_retention_days
  # flow_logs_s3_bucket_arn     = var.flow_logs_s3_bucket_arn
  # flow_logs_kms_key_id        = var.flow_logs_kms_key_id

  # VPC Endpoints - Gateway
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  # VPC Endpoints - Interface
  enable_ecr_api_endpoint     = var.enable_ecr_api_endpoint
  enable_ecr_dkr_endpoint     = var.enable_ecr_dkr_endpoint
  enable_logs_endpoint        = var.enable_logs_endpoint
  enable_ssm_endpoint         = var.enable_ssm_endpoint
  enable_ec2messages_endpoint = var.enable_ec2messages_endpoint
  enable_ssmmessages_endpoint = var.enable_ssmmessages_endpoint
  enable_sts_endpoint         = var.enable_sts_endpoint

  # EKS Integration
  enable_eks_tags  = var.enable_eks_tags
  eks_cluster_name = var.eks_cluster_name

  # Tagging
  tags                    = var.tags
  vpc_tags                = var.vpc_tags
  public_subnet_tags      = var.public_subnet_tags
  private_app_subnet_tags = var.private_app_subnet_tags
  private_db_subnet_tags  = var.private_db_subnet_tags
  # isolated_subnet_tags    = var.isolated_subnet_tags
}

################################################################################
# Optional: RDS Subnet Group
# Uncomment to create RDS subnet group for database deployments
################################################################################

# resource "aws_db_subnet_group" "main" {
#   name       = "${var.vpc_name}-db-subnet-group"
#   subnet_ids = module.vpc.private_db_subnet_ids
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-db-subnet-group"
#     }
#   )
# }

################################################################################
# Optional: ElastiCache Subnet Group
# Uncomment to create ElastiCache subnet group
################################################################################

# resource "aws_elasticache_subnet_group" "main" {
#   name       = "${var.vpc_name}-cache-subnet-group"
#   subnet_ids = module.vpc.private_db_subnet_ids
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-cache-subnet-group"
#     }
#   )
# }

################################################################################
# Optional: Redshift Subnet Group
# Uncomment to create Redshift subnet group
################################################################################

# resource "aws_redshift_subnet_group" "main" {
#   name       = "${var.vpc_name}-redshift-subnet-group"
#   subnet_ids = module.vpc.private_db_subnet_ids
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-redshift-subnet-group"
#     }
#   )
# }

################################################################################
# Optional: Transit Gateway Attachment
# Uncomment to attach VPC to Transit Gateway
################################################################################

# resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
#   transit_gateway_id = var.transit_gateway_id
#   vpc_id             = module.vpc.vpc_id
#   subnet_ids         = module.vpc.private_app_subnet_ids
#
#   dns_support  = "enable"
#   ipv6_support = var.enable_ipv6 ? "enable" : "disable"
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-tgw-attachment"
#     }
#   )
# }

# # Add routes to Transit Gateway
# resource "aws_route" "tgw_private_app" {
#   count = length(module.vpc.private_app_route_table_ids)
#
#   route_table_id         = module.vpc.private_app_route_table_ids[count.index]
#   destination_cidr_block = "10.0.0.0/8"  # Corporate network CIDR
#   transit_gateway_id     = var.transit_gateway_id
#
#   depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
# }

# resource "aws_route" "tgw_private_db" {
#   count = length(module.vpc.private_db_route_table_ids)
#
#   route_table_id         = module.vpc.private_db_route_table_ids[count.index]
#   destination_cidr_block = "10.0.0.0/8"  # Corporate network CIDR
#   transit_gateway_id     = var.transit_gateway_id
#
#   depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
# }

################################################################################
# Optional: VPC Peering Connection
# Uncomment to create VPC peering with another VPC
################################################################################

# resource "aws_vpc_peering_connection" "peer" {
#   vpc_id      = module.vpc.vpc_id
#   peer_vpc_id = var.peer_vpc_id
#   auto_accept = true
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-to-${var.peer_vpc_name}"
#     }
#   )
# }

# # Add routes for VPC peering
# resource "aws_route" "peer_private_app" {
#   count = length(module.vpc.private_app_route_table_ids)
#
#   route_table_id            = module.vpc.private_app_route_table_ids[count.index]
#   destination_cidr_block    = var.peer_vpc_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

################################################################################
# Optional: Custom Security Groups
# Uncomment to create application-specific security groups
################################################################################

# # Application Load Balancer Security Group
# resource "aws_security_group" "alb" {
#   name_prefix = "${var.vpc_name}-alb-"
#   description = "Security group for Application Load Balancer"
#   vpc_id      = module.vpc.vpc_id
#
#   ingress {
#     description = "HTTPS from internet"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   ingress {
#     description = "HTTP from internet"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-alb-sg"
#     }
#   )
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Application Security Group
# resource "aws_security_group" "app" {
#   name_prefix = "${var.vpc_name}-app-"
#   description = "Security group for application tier"
#   vpc_id      = module.vpc.vpc_id
#
#   ingress {
#     description     = "HTTP from ALB"
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }
#
#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-app-sg"
#     }
#   )
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Database Security Group
# resource "aws_security_group" "db" {
#   name_prefix = "${var.vpc_name}-db-"
#   description = "Security group for database tier"
#   vpc_id      = module.vpc.vpc_id
#
#   ingress {
#     description     = "PostgreSQL from application"
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.app.id]
#   }
#
#   egress {
#     description = "All outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-db-sg"
#     }
#   )
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
