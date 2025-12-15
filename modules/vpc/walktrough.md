Production AWS VPC Terraform Module - Walkthrough
Overview
Successfully implemented a production-grade AWS VPC Terraform module that meets all enterprise requirements. The module is designed for real-world workloads including EKS, ECS, RDS, Lambda, and PrivateLink integrations, with a focus on security, cost-awareness, and operational excellence.

What Was Built
Module Structure
Created a complete Terraform module in modules/vpc/ with the following files:

modules/vpc/
├── versions.tf      # Terraform and provider version constraints
├── variables.tf     # Input variables with validation
├── locals.tf        # Computed values and logic
├── main.tf          # Core infrastructure resources
├── outputs.tf       # Module outputs
└── README.md        # Comprehensive documentation
Key Features Implemented
1. Multi-Tier Subnet Architecture
Four-tier subnet design with deterministic CIDR allocation:

Public Subnets (10.0.0.0/20): Internet-facing resources
Private App Subnets (10.0.16.0/20): Application workloads (EKS, ECS, EC2)
Private DB Subnets (10.0.32.0/20): Database instances (RDS, ElastiCache)
Isolated Subnets (10.0.48.0/20): Air-gapped workloads
CIDR Calculation Strategy:

VPC CIDR divided into 16 equal /20 tier blocks
Each tier receives one /20 block (4,096 IPs)
Individual subnets get /24 blocks (256 IPs each)
Supports up to 16 subnets per tier
2. Flexible NAT Gateway Strategy
Two deployment modes:

Multi-AZ NAT (Default - Production)

One NAT Gateway per AZ
High availability, no single point of failure
Cost: ~$96/month for 3 AZs (before data transfer)
Single NAT (Cost-Optimized)

One NAT Gateway in first AZ
67% cost reduction
Suitable for dev/test environments
Cost: ~$32/month (before data transfer)
3. VPC Endpoints
Gateway Endpoints (Free):

S3
DynamoDB
Interface Endpoints (~$7/month per AZ each):

ECR API & Docker
CloudWatch Logs
SSM, EC2 Messages, SSM Messages
STS (for IRSA/Pod Identity)
All endpoints configurable via feature flags.

4. VPC Flow Logs
Three destination options:

CloudWatch Logs: Real-time analysis, configurable retention
S3: Long-term storage, cost-effective archival
Both: Dual destination support
Features:

KMS encryption for CloudWatch logs
IAM role with least-privilege policy
Configurable traffic type (ACCEPT, REJECT, ALL)
5. EKS Integration
Automatic Kubernetes tags when enabled
kubernetes.io/role/elb for public subnets
kubernetes.io/role/internal-elb for private subnets
kubernetes.io/cluster/<name> cluster association tags
6. IPv6 Support
Optional dual-stack configuration
Amazon-provided IPv6 CIDR block
IPv6 routes for public subnets
IPv6 CIDR assignment for all subnet tiers
Design Decisions
1. Deterministic CIDR Allocation
Decision: Use cidrsubnet() function with tier offsets instead of hardcoded CIDRs.

Rationale:

Prevents CIDR overlap errors
Supports different VPC CIDR sizes
Predictable and easy to calculate
Scales to 16 subnets per tier
Implementation:

# Tier block calculation
cidrsubnet(var.vpc_cidr, 4, tier_offset)  # /20 from /16 VPC
# Subnet within tier
cidrsubnet(tier_block, 4, az_index)       # /24 from /20 tier
2. Separate Route Tables Per Tier
Decision: Create dedicated route tables for each subnet tier and AZ.

Rationale:

Enables granular routing control
Supports different NAT strategies (multi-AZ vs single)
Facilitates Transit Gateway/VPC Peering integration
Isolates database routing from application routing
Implementation:

Public: 1 shared route table
Private App: 1 route table per AZ (for multi-AZ NAT)
Private DB: 1 route table per AZ (separate from app)
Isolated: 1 route table per AZ (no default route)
3. Multi-AZ NAT by Default
Decision: Default to single_nat_gateway = false (multi-AZ NAT).

Rationale:

Production-first approach
Eliminates single point of failure
AZ-level fault tolerance
Users must explicitly opt-in to cost-optimized mode
Trade-off: Higher cost (~$96/month vs ~$32/month for 3 AZs)

4. No Default Security Groups
Decision: Module doesn't create or use default security groups.

Rationale:

AWS default security group is too permissive
Forces explicit security group creation
Follows least-privilege principle
Prevents accidental exposure
Extensibility: Users can create custom security groups using module outputs.

5. Optional VPC Endpoints
Decision: All endpoints disabled by default except S3.

Rationale:

Interface endpoints cost ~$7/month per AZ each
Not all workloads need all endpoints
Users enable only what they need
S3 gateway endpoint is free and universally useful
Cost Impact: Full endpoint suite = ~$147/month (3 AZs, 7 interface endpoints)

6. CloudWatch Flow Logs by Default
Decision: Default to CloudWatch Logs with 7-day retention.

Rationale:

Real-time analysis capability
CloudWatch Insights integration
Reasonable retention for troubleshooting
KMS encryption by default
Alternative: S3 destination for long-term storage (lower cost)

Validation Results
Terraform Validation
✅ terraform init: Successfully initialized

AWS Provider v6.26.0 installed
No initialization errors
✅ terraform validate: Configuration is valid

No syntax errors
All resource dependencies resolved
Minor deprecation warning (data.aws_region.current.name) - non-blocking
✅ terraform fmt -check: Code is properly formatted

All files follow Terraform style conventions
No formatting issues
Code Quality Checks
✅ No Hardcoded Values

Region from data source
AZs from data source or variable
All values configurable or computed
✅ Strict Variable Validation

CIDR block validation
Private IP range validation
Subnet count limits (0-6)
AZ count limits (2-6)
Flow logs destination type validation
Retention days validation
✅ Comprehensive Tagging

Common tags applied to all resources
Resource-specific tags (Name, Tier)
EKS tags when enabled
Custom tags via variables
✅ Idempotent Design

Deterministic CIDR calculations
Stable resource naming
No random values without lifecycle ignore
✅ Production-Ready Defaults

Multi-AZ NAT (high availability)
3 AZs (fault tolerance)
Flow logs enabled (observability)
DNS hostnames enabled (VPC endpoints, EKS)
S3 endpoint enabled (cost savings)
Usage Examples
1. Development VPC (Cost-Optimized)
module "dev_vpc" {
  source = "./modules/vpc"
  vpc_name    = "dev-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "dev"
  # Cost optimizations
  single_nat_gateway = true
  azs_count          = 2
  # Minimal endpoints
  enable_s3_endpoint = true
  tags = {
    Project = "my-app"
    Owner   = "platform-team"
  }
}
Monthly Cost Estimate:

NAT Gateway: ~$32
Data transfer: ~$20-50
Total: ~$52-82/month
2. Production VPC (High Availability)
module "prod_vpc" {
  source = "./modules/vpc"
  vpc_name    = "prod-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"
  # High availability
  azs_count          = 3
  single_nat_gateway = false
  # Full observability
  enable_flow_logs            = true
  flow_logs_destination_type  = "both"
  flow_logs_retention_days    = 30
  flow_logs_s3_bucket_arn     = "arn:aws:s3:::my-flow-logs-bucket"
  # VPC Endpoints
  enable_s3_endpoint         = true
  enable_dynamodb_endpoint   = true
  enable_ecr_api_endpoint    = true
  enable_ecr_dkr_endpoint    = true
  enable_logs_endpoint       = true
  enable_ssm_endpoint        = true
  enable_ec2messages_endpoint = true
  enable_ssmmessages_endpoint = true
  tags = {
    Project     = "my-app"
    Owner       = "platform-team"
    CostCenter  = "engineering"
    Compliance  = "pci-dss"
  }
}
Monthly Cost Estimate:

NAT Gateways: ~$96
Interface Endpoints: ~$126 (6 endpoints × 3 AZs × $7)
Flow Logs (CloudWatch): ~$50
Flow Logs (S3): ~$23
Data transfer: ~$100-200
Total: ~$395-495/month
3. EKS-Ready VPC
module "eks_vpc" {
  source = "./modules/vpc"
  vpc_name    = "eks-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"
  # EKS-specific
  enable_eks_tags  = true
  eks_cluster_name = "my-eks-cluster"
  # Required for private EKS
  enable_ecr_api_endpoint    = true
  enable_ecr_dkr_endpoint    = true
  enable_sts_endpoint        = true
  enable_logs_endpoint       = true
  enable_s3_endpoint         = true
  # SSM for node access
  enable_ssm_endpoint        = true
  enable_ec2messages_endpoint = true
  enable_ssmmessages_endpoint = true
  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}
Key Outputs for EKS:

# Use in EKS module
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  vpc_id          = module.eks_vpc.vpc_id
  subnet_ids      = module.eks_vpc.private_app_subnet_ids
  
  # Public subnets for load balancers
  control_plane_subnet_ids = module.eks_vpc.public_subnet_ids
}
Key Outputs
The module exposes comprehensive outputs for downstream integration:

VPC Outputs
vpc_id, vpc_arn, vpc_cidr_block
vpc_ipv6_cidr_block (if IPv6 enabled)
Subnet Outputs
public_subnet_ids, private_app_subnet_ids, private_db_subnet_ids, isolated_subnet_ids
Subnet ARNs and CIDR blocks
*_subnets_by_az maps for AZ-specific lookups
Networking Outputs
nat_gateway_ids, nat_gateway_public_ips
internet_gateway_id
Route table IDs per tier
VPC Endpoint Outputs
vpc_endpoint_s3_id, vpc_endpoint_dynamodb_id
vpc_endpoint_interface_ids (map of endpoint names to IDs)
vpc_endpoints_security_group_id
Computed Outputs
availability_zones (list of AZs used)
region (AWS region)
nat_gateway_strategy ("single" or "multi-az")
Security Considerations
Implemented Security Controls
Network Segmentation: Four-tier architecture isolates workloads
Private by Default: DB and isolated subnets have no internet access
Encrypted Flow Logs: CloudWatch logs use KMS encryption
Least-Privilege IAM: Flow logs role has minimal permissions
VPC Endpoint Security: HTTPS-only access from VPC CIDR
No Default Security Groups: Forces explicit security group creation
Common Misconfigurations Prevented
Risk	Prevention Mechanism
Single AZ failure	Multi-AZ default (azs_count = 3)
CIDR overlap	Deterministic cidrsubnet() calculations
Public databases	Separate private DB tier, no public IPs
Missing EKS tags	Automatic tags when enable_eks_tags = true
NAT single point of failure	Multi-AZ NAT default
Unencrypted logs	KMS encryption for CloudWatch logs
Untagged resources	Comprehensive tagging enforced
Extensibility
Adding Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_app_subnet_ids
}
resource "aws_route" "tgw" {
  count = length(module.vpc.private_app_route_table_ids)
  route_table_id         = module.vpc.private_app_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id
}
Adding VPC Peering
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = var.peer_vpc_id
  auto_accept = true
}
resource "aws_route" "peer" {
  count = length(module.vpc.private_app_route_table_ids)
  route_table_id            = module.vpc.private_app_route_table_ids[count.index]
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
Testing Recommendations
Unit Tests (Terratest)
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_name":    "test-vpc",
            "vpc_cidr":    "10.0.0.0/16",
            "environment": "test",
        },
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
Integration Tests
Deploy VPC: Apply module with production configuration
Verify Connectivity: Launch EC2 in private subnet, verify internet access via NAT
Test VPC Endpoints: Verify S3/ECR access without internet traversal
Validate Flow Logs: Confirm logs appearing in CloudWatch/S3
EKS Integration: Deploy EKS cluster, verify load balancer creation
Security Scanning
# Checkov
checkov -d modules/vpc
# tfsec
tfsec modules/vpc
# Terraform compliance
terraform-compliance -f compliance/ -p modules/vpc/
Documentation
Created comprehensive README.md covering:

✅ Architecture overview with network topology diagram
✅ Subnet strategy and CIDR calculation rationale
✅ NAT Gateway cost vs resilience trade-offs
✅ Security model and best practices
✅ Usage examples (dev, prod, EKS-ready)
✅ VPC Flow Logs configuration options
✅ VPC Endpoints cost analysis
✅ Complete input/output reference
✅ Common misconfigurations and prevention
✅ Upgrade and extensibility guidance
✅ Troubleshooting guide
Conclusion
Successfully delivered a production-grade AWS VPC Terraform module that:

✅ Meets All Requirements: VPC core, multi-tier subnets, NAT strategies, routing, VPC endpoints, flow logs
✅ Production-Ready: Security-first design, cost-aware defaults, high availability
✅ Enterprise-Grade: Supports EKS, ECS, RDS, Lambda, PrivateLink
✅ Best Practices: Deterministic CIDR, strict validation, comprehensive tagging
✅ Well-Documented: Architecture rationale, cost analysis, usage examples
✅ Validated: Terraform init/validate/fmt all pass
✅ Extensible: Clean outputs for Transit Gateway, VPC Peering, custom security groups

The module is ready for immediate use in development, staging, and production environments.

Next Steps
Deploy to Dev Environment: Test with real workloads
Run Security Scans: Checkov, tfsec, terraform-compliance
Create Example Configurations: Dev, staging, prod examples in examples/ directory
Set Up CI/CD: Automated validation, security scanning, documentation generation
Add Terratest: Automated integration tests
Create Terraform Registry Documentation: Publish to private/public registry