# AWS VPC Terraform Module

Production-grade AWS VPC module designed for enterprise workloads including EKS, ECS, RDS, Lambda, and PrivateLink integrations. This module implements AWS networking best practices with a security-first, cost-aware, and highly scalable architecture.

## Features

- **Multi-AZ Architecture**: Automatic subnet distribution across availability zones for high availability
- **Four-Tier Subnet Design**: Public, Private Application, Private Database, and Isolated subnets
- **Deterministic CIDR Allocation**: Predictable subnet addressing using `cidrsubnet()` calculations
- **Flexible NAT Strategy**: Multi-AZ NAT for production resilience or single NAT for cost optimization
- **VPC Endpoints**: Gateway and Interface endpoints for private AWS service connectivity
- **VPC Flow Logs**: CloudWatch and S3 destination support with encryption
- **EKS-Ready**: Automatic Kubernetes tags for seamless EKS integration
- **IPv6 Support**: Optional dual-stack configuration
- **Zero Hardcoded Values**: Fully region and AZ agnostic

## Architecture

### Network Topology

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.0.0/20)
│   ├── us-east-1a: 10.0.0.0/24   → Internet Gateway
│   ├── us-east-1b: 10.0.1.0/24   → Internet Gateway
│   └── us-east-1c: 10.0.2.0/24   → Internet Gateway
│
├── Private App Subnets (10.0.16.0/20)
│   ├── us-east-1a: 10.0.16.0/24  → NAT Gateway (AZ-A)
│   ├── us-east-1b: 10.0.17.0/24  → NAT Gateway (AZ-B)
│   └── us-east-1c: 10.0.18.0/24  → NAT Gateway (AZ-C)
│
├── Private DB Subnets (10.0.32.0/20)
│   ├── us-east-1a: 10.0.32.0/24  → NAT Gateway (AZ-A)
│   ├── us-east-1b: 10.0.33.0/24  → NAT Gateway (AZ-B)
│   └── us-east-1c: 10.0.34.0/24  → NAT Gateway (AZ-C)
│
└── Isolated Subnets (10.0.48.0/20)
    ├── us-east-1a: 10.0.48.0/24  → VPC-local only
    ├── us-east-1b: 10.0.49.0/24  → VPC-local only
    └── us-east-1c: 10.0.50.0/24  → VPC-local only
```

### Routing Strategy

| Subnet Tier | Default Route | Use Case |
|-------------|---------------|----------|
| **Public** | 0.0.0.0/0 → IGW | Internet-facing load balancers, NAT Gateways, bastion hosts |
| **Private App** | 0.0.0.0/0 → NAT | EKS worker nodes, ECS tasks, application EC2 instances |
| **Private DB** | 0.0.0.0/0 → NAT | RDS instances, ElastiCache, Redshift clusters |
| **Isolated** | No default route | Highly sensitive workloads, compliance-required isolation |

## Subnet Strategy Rationale

### CIDR Calculation

The module uses a **deterministic CIDR allocation strategy** to ensure predictable addressing and prevent overlap:

1. **VPC CIDR** is divided into 16 equal `/20` tier blocks (4,096 IPs each)
2. Each **subnet tier** (public, private-app, private-db, isolated) receives one `/20` block
3. Within each tier, **individual subnets** receive `/24` blocks (256 IPs each)

**Example with 10.0.0.0/16 VPC:**

```hcl
# Tier blocks (each /20 = 4,096 IPs)
Public Tier:      10.0.0.0/20   (offset 0)
Private App Tier: 10.0.16.0/20  (offset 1)
Private DB Tier:  10.0.32.0/20  (offset 2)
Isolated Tier:    10.0.48.0/20  (offset 3)

# Individual subnets within Public Tier (each /24 = 256 IPs)
AZ-A: 10.0.0.0/24   (index 0)
AZ-B: 10.0.1.0/24   (index 1)
AZ-C: 10.0.2.0/24   (index 2)
```

**Benefits:**
- **Predictable**: CIDR blocks are deterministic and easy to calculate
- **Scalable**: Supports up to 16 subnets per tier
- **Flexible**: Can accommodate different VPC CIDR sizes (/16, /20, /21, etc.)
- **No Overlap**: Mathematical guarantee of non-overlapping subnets

### Why Four Tiers?

1. **Public Subnets**: Required for resources that need direct internet access (ALB, NAT)
2. **Private App Subnets**: Isolates application workloads from direct internet exposure
3. **Private DB Subnets**: Separate tier prevents accidental database exposure, enables granular security controls
4. **Isolated Subnets**: For compliance requirements (PCI-DSS, HIPAA) or air-gapped workloads

## NAT Gateway: Cost vs Resilience Trade-offs

### Multi-AZ NAT (Default - Production Recommended)

**Configuration:**
```hcl
single_nat_gateway = false  # One NAT per AZ
```

**Costs (3 AZs):**
- NAT Gateway: ~$32/month × 3 = **$96/month**
- Data Processing: $0.045/GB × traffic
- **Total**: ~$96-300/month depending on traffic

**Pros:**
- ✅ High availability - no single point of failure
- ✅ AZ-level fault tolerance
- ✅ Better performance (local NAT per AZ)
- ✅ Production-grade resilience

**Cons:**
- ❌ Higher cost
- ❌ 3× NAT Gateway charges

**Use Cases:** Production workloads, mission-critical applications, SLA-driven environments

---

### Single NAT (Cost-Optimized)

**Configuration:**
```hcl
single_nat_gateway = true  # One NAT in first AZ
```

**Costs:**
- NAT Gateway: **$32/month**
- Data Processing: $0.045/GB × traffic
- **Total**: ~$32-150/month depending on traffic

**Pros:**
- ✅ 67% cost reduction vs multi-AZ
- ✅ Simpler architecture
- ✅ Suitable for dev/test environments

**Cons:**
- ❌ Single point of failure
- ❌ If NAT's AZ fails, all private subnets lose internet
- ❌ Cross-AZ data transfer charges
- ❌ Not production-grade

**Use Cases:** Development, testing, sandbox environments, cost-constrained non-critical workloads

---

### Cost Comparison Table

| Configuration | NAT Cost/Month | Resilience | Production Ready | Recommended For |
|---------------|----------------|------------|------------------|-----------------|
| **Multi-AZ NAT** | ~$96 | High | ✅ Yes | Production, critical workloads |
| **Single NAT** | ~$32 | Low | ❌ No | Dev, test, sandbox |
| **No NAT** | $0 | N/A | ⚠️ Limited | Fully private workloads with VPC endpoints |

## Security Model

### Defense in Depth

1. **Network Segmentation**: Four-tier subnet architecture isolates workloads
2. **Private by Default**: Database and isolated subnets have no internet access
3. **Least Privilege Routing**: Separate route tables per tier enable granular control
4. **VPC Endpoints**: Private connectivity to AWS services without internet traversal
5. **No Default Security Groups**: Module doesn't use AWS default security group (too permissive)

### Security Best Practices Implemented

- ✅ **No Public Database Subnets**: Separate private DB tier prevents accidental exposure
- ✅ **Encrypted Flow Logs**: CloudWatch logs encrypted with KMS
- ✅ **IAM Roles for Flow Logs**: Least-privilege IAM policy for log delivery
- ✅ **VPC Endpoint Security Groups**: HTTPS-only access from VPC CIDR
- ✅ **Isolated Subnets**: No default route for air-gapped workloads
- ✅ **Optional NACLs**: Stateless firewall support (disabled by default)

### Common Misconfigurations Prevented

| Misconfiguration | How This Module Prevents It |
|------------------|------------------------------|
| Single AZ deployment | Enforces multi-AZ by default (`azs_count = 3`) |
| Overlapping CIDRs | Deterministic `cidrsubnet()` calculations |
| Missing EKS tags | Automatic tags when `enable_eks_tags = true` |
| Public database subnets | Separate private DB tier with no public IP assignment |
| No NAT redundancy | Multi-AZ NAT is default (`single_nat_gateway = false`) |
| Unencrypted flow logs | CloudWatch logs encrypted by default |
| Untagged resources | Comprehensive tagging strategy enforced |

## Usage Examples

### Basic VPC (Development)

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name    = "dev-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "dev"

  # Cost-optimized for development
  single_nat_gateway = true
  
  # Minimal endpoints
  enable_s3_endpoint = true

  tags = {
    Project = "my-app"
    Owner   = "platform-team"
  }
}
```

### Production VPC (Multi-AZ, High Availability)

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name    = "prod-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"

  # High availability
  azs_count          = 3
  single_nat_gateway = false  # Multi-AZ NAT

  # Full observability
  enable_flow_logs            = true
  flow_logs_destination_type  = "cloud-watch-logs"
  flow_logs_retention_days    = 30
  flow_logs_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/..."

  # VPC Endpoints for private connectivity
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
```

### EKS-Ready VPC

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name    = "eks-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"

  # EKS-specific configuration
  enable_eks_tags  = true
  eks_cluster_name = "my-eks-cluster"

  # Required for private EKS clusters
  enable_ecr_api_endpoint    = true
  enable_ecr_dkr_endpoint    = true
  enable_sts_endpoint        = true
  enable_logs_endpoint       = true
  enable_s3_endpoint         = true

  # SSM for node access without bastion
  enable_ssm_endpoint        = true
  enable_ec2messages_endpoint = true
  enable_ssmmessages_endpoint = true

  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}
```

### IPv6 Dual-Stack VPC

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name    = "ipv6-vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"

  # Enable IPv6
  enable_ipv6 = true

  # Rest of configuration...
}
```

### Custom Subnet Configuration

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name    = "custom-vpc"
  vpc_cidr    = "10.100.0.0/16"
  environment = "prod"

  # Custom AZ selection
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  # Custom subnet counts
  public_subnet_count      = 3
  private_app_subnet_count = 3
  private_db_subnet_count  = 3
  isolated_subnet_count    = 2

  # Custom subnet sizing (creates /22 subnets from /16 VPC)
  subnet_newbits = 6
}
```

## VPC Flow Logs

### CloudWatch Logs (Default)

**Best for:** Real-time analysis, short-term retention, CloudWatch Insights queries

```hcl
enable_flow_logs            = true
flow_logs_destination_type  = "cloud-watch-logs"
flow_logs_retention_days    = 7
flow_logs_kms_key_id        = "arn:aws:kms:..."  # Optional
```

**Costs:**
- Ingestion: $0.50/GB
- Storage: $0.03/GB/month
- **Example**: 100GB/month = $50 ingestion + $3 storage = **$53/month**

---

### S3 (Long-Term Storage)

**Best for:** Long-term retention, compliance, cost-effective archival

```hcl
enable_flow_logs            = true
flow_logs_destination_type  = "s3"
flow_logs_s3_bucket_arn     = "arn:aws:s3:::my-flow-logs-bucket"
```

**Costs:**
- Storage: $0.023/GB/month (S3 Standard)
- **Example**: 1TB/month = **$23/month**

---

### Both Destinations

```hcl
enable_flow_logs            = true
flow_logs_destination_type  = "both"
flow_logs_s3_bucket_arn     = "arn:aws:s3:::my-flow-logs-bucket"
flow_logs_retention_days    = 7
```

## VPC Endpoints

### Gateway Endpoints (Free)

- **S3**: `enable_s3_endpoint = true`
- **DynamoDB**: `enable_dynamodb_endpoint = true`

**Cost:** $0/month  
**Recommendation:** Always enable for production

---

### Interface Endpoints (~$7/month per AZ each)

| Endpoint | Variable | Required For | Monthly Cost (3 AZs) |
|----------|----------|--------------|----------------------|
| ECR API | `enable_ecr_api_endpoint` | Private EKS/ECS | ~$21 |
| ECR Docker | `enable_ecr_dkr_endpoint` | Private EKS/ECS | ~$21 |
| CloudWatch Logs | `enable_logs_endpoint` | Private logging | ~$21 |
| SSM | `enable_ssm_endpoint` | Session Manager | ~$21 |
| EC2 Messages | `enable_ec2messages_endpoint` | Session Manager | ~$21 |
| SSM Messages | `enable_ssmmessages_endpoint` | Session Manager | ~$21 |
| STS | `enable_sts_endpoint` | IRSA/Pod Identity | ~$21 |

**Total for all endpoints:** ~$147/month (3 AZs)

**Cost Savings:** VPC endpoints eliminate NAT data processing charges ($0.045/GB), which can offset the endpoint costs for high-traffic workloads.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_cidr` | IPv4 CIDR block for the VPC | `string` | - | yes |
| `vpc_name` | Name of the VPC | `string` | - | yes |
| `environment` | Environment name (dev, staging, prod) | `string` | - | yes |
| `availability_zones` | List of AZs to use (auto-selected if empty) | `list(string)` | `[]` | no |
| `azs_count` | Number of AZs when availability_zones is empty | `number` | `3` | no |
| `public_subnet_count` | Number of public subnets | `number` | `3` | no |
| `private_app_subnet_count` | Number of private app subnets | `number` | `3` | no |
| `private_db_subnet_count` | Number of private DB subnets | `number` | `3` | no |
| `isolated_subnet_count` | Number of isolated subnets | `number` | `0` | no |
| `enable_internet_gateway` | Create Internet Gateway | `bool` | `true` | no |
| `enable_nat_gateway` | Create NAT Gateway(s) | `bool` | `true` | no |
| `single_nat_gateway` | Use single NAT (cost-optimized) | `bool` | `false` | no |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `true` | no |
| `flow_logs_destination_type` | Flow logs destination (cloud-watch-logs, s3, both) | `string` | `"cloud-watch-logs"` | no |
| `enable_s3_endpoint` | Create S3 Gateway Endpoint | `bool` | `true` | no |
| `enable_eks_tags` | Add Kubernetes tags for EKS | `bool` | `false` | no |
| `eks_cluster_name` | EKS cluster name for tagging | `string` | `""` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

See [variables.tf](./variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_app_subnet_ids` | List of private app subnet IDs |
| `private_db_subnet_ids` | List of private DB subnet IDs |
| `isolated_subnet_ids` | List of isolated subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_public_ips` | List of NAT Gateway public IPs |
| `internet_gateway_id` | ID of the Internet Gateway |
| `vpc_endpoint_s3_id` | ID of S3 VPC Endpoint |
| `availability_zones` | List of AZs used |

See [outputs.tf](./outputs.tf) for complete list.

## Upgrade and Extensibility

### Adding Transit Gateway Integration

```hcl
# In your root module
module "vpc" {
  source = "./modules/vpc"
  # ... vpc configuration
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_app_subnet_ids
}

# Add TGW routes to private route tables
resource "aws_route" "tgw" {
  count = length(module.vpc.private_app_route_table_ids)

  route_table_id         = module.vpc.private_app_route_table_ids[count]
  destination_cidr_block = "10.0.0.0/8"  # Corporate network
  transit_gateway_id     = var.transit_gateway_id
}
```

### Adding VPC Peering

```hcl
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = var.peer_vpc_id
  auto_accept = true
}

resource "aws_route" "peer" {
  count = length(module.vpc.private_app_route_table_ids)

  route_table_id            = module.vpc.private_app_route_table_ids[count]
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
```

### Adding Custom Security Groups

```hcl
resource "aws_security_group" "app" {
  name_prefix = "app-"
  description = "Security group for application tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Troubleshooting

### Issue: "Error creating VPC: VpcLimitExceeded"

**Cause:** AWS account VPC limit reached (default 5 per region)

**Solution:** Request limit increase via AWS Support or delete unused VPCs

---

### Issue: "Error creating NAT Gateway: NatGatewayLimitExceeded"

**Cause:** NAT Gateway limit reached (default 5 per AZ)

**Solution:** Request limit increase or use `single_nat_gateway = true`

---

### Issue: Private subnets can't reach internet

**Cause:** NAT Gateway not created or route missing

**Solution:** Verify `enable_nat_gateway = true` and check route table associations

---

### Issue: VPC Endpoint not working

**Cause:** Security group blocking traffic or private DNS disabled

**Solution:** 
- Verify security group allows HTTPS (443) from VPC CIDR
- Ensure `private_dns_enabled = true` for interface endpoints
- Check subnet route tables include endpoint routes

---

### Issue: EKS cluster can't create load balancers

**Cause:** Missing Kubernetes subnet tags

**Solution:** Set `enable_eks_tags = true` and `eks_cluster_name = "your-cluster"`

## Requirements

- Terraform >= 1.6.0
- AWS Provider >= 5.0.0

## License

This module is licensed under the MIT License.

## Authors

Created by Platform Engineering Team

## Support

For issues, questions, or contributions, please open an issue in the repository.
