# VPC Module Examples

This directory contains example configurations demonstrating how to use the VPC module in different scenarios.

## Available Examples

### Production Example (`production/`)

Full-featured production VPC with:
- Multi-AZ NAT Gateways (high availability)
- All VPC endpoints enabled (ECR, CloudWatch, SSM, STS)
- VPC Flow Logs to CloudWatch
- EKS-ready configuration
- Optional Transit Gateway and VPC Peering
- Custom security groups for ALB, app, and database tiers

**Monthly Cost:** ~$393-493/month

**Use Cases:**
- Production workloads
- Mission-critical applications
- EKS/ECS clusters
- Compliance-required environments

### Development Example (`development/`)

Cost-optimized development VPC with:
- Single NAT Gateway (cost savings)
- Minimal VPC endpoints (S3 only)
- Reduced AZ count (2 instead of 3)
- Shorter flow log retention (7 days)

**Monthly Cost:** ~$52-82/month

**Use Cases:**
- Development environments
- Testing and sandbox
- CI/CD environments
- Non-critical workloads

## Usage

### Quick Start

1. **Choose an example** based on your use case
2. **Copy the example** to your project:
   ```bash
   cp -r examples/production my-vpc-config
   cd my-vpc-config
   ```

3. **Customize** `terraform.tfvars`:
   ```hcl
   vpc_name    = "my-vpc"
   vpc_cidr    = "10.0.0.0/16"
   environment = "prod"
   # ... customize other values
   ```

4. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Customization Guide

#### Changing VPC CIDR

```hcl
# terraform.tfvars
vpc_cidr = "10.100.0.0/16"  # Change to your desired CIDR
```

#### Adjusting Subnet Counts

```hcl
# terraform.tfvars
public_subnet_count      = 3  # One per AZ
private_app_subnet_count = 3
private_db_subnet_count  = 3
isolated_subnet_count    = 0  # Set to 3 if needed
```

#### Enabling/Disabling VPC Endpoints

```hcl
# terraform.tfvars

# Gateway endpoints (free)
enable_s3_endpoint       = true
enable_dynamodb_endpoint = false

# Interface endpoints (~$7/month per AZ each)
enable_ecr_api_endpoint     = true   # Required for private EKS/ECS
enable_ecr_dkr_endpoint     = true   # Required for private EKS/ECS
enable_logs_endpoint        = true
enable_ssm_endpoint         = true
enable_ec2messages_endpoint = true
enable_ssmmessages_endpoint = true
enable_sts_endpoint         = true   # Required for IRSA
```

#### Switching NAT Strategy

```hcl
# terraform.tfvars

# Production (multi-AZ NAT)
single_nat_gateway = false  # ~$96/month for 3 AZs

# Development (single NAT)
single_nat_gateway = true   # ~$32/month
```

#### Configuring Flow Logs

```hcl
# terraform.tfvars

# CloudWatch Logs
flow_logs_destination_type = "cloud-watch-logs"
flow_logs_retention_days   = 30

# S3 (requires bucket)
# flow_logs_destination_type = "s3"
# flow_logs_s3_bucket_arn    = "arn:aws:s3:::my-flow-logs-bucket"

# Both
# flow_logs_destination_type = "both"
```

#### Enabling EKS Tags

```hcl
# terraform.tfvars
enable_eks_tags  = true
eks_cluster_name = "my-eks-cluster"
```

## Advanced Configurations

### Transit Gateway Integration

Uncomment the Transit Gateway section in `main.tf`:

```hcl
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_app_subnet_ids
  # ...
}
```

Then set the variable:
```hcl
# terraform.tfvars
transit_gateway_id = "tgw-0123456789abcdef0"
```

### VPC Peering

Uncomment the VPC Peering section in `main.tf`:

```hcl
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = var.peer_vpc_id
  # ...
}
```

Then set the variables:
```hcl
# terraform.tfvars
peer_vpc_id   = "vpc-0123456789abcdef0"
peer_vpc_name = "shared-services-vpc"
peer_vpc_cidr = "10.1.0.0/16"
```

### Custom Security Groups

Uncomment the security group sections in `main.tf` to create:
- ALB security group (HTTPS/HTTP from internet)
- Application security group (app port from ALB)
- Database security group (DB port from app)

### Subnet Groups

Uncomment the subnet group sections in `main.tf` to create:
- RDS subnet group
- ElastiCache subnet group
- Redshift subnet group

## Cost Optimization Tips

### Development/Test Environments

1. **Use single NAT**: `single_nat_gateway = true` (saves ~$64/month)
2. **Reduce AZ count**: `azs_count = 2` (saves ~$32/month on NAT)
3. **Disable unused endpoints**: Only enable S3 (saves ~$147/month)
4. **Shorter log retention**: `flow_logs_retention_days = 7` (saves ~$30/month)
5. **Use S3 for flow logs**: `flow_logs_destination_type = "s3"` (saves ~$27/month)

**Total Savings:** ~$300/month

### Production Environments

1. **Enable all required endpoints**: Saves NAT data transfer costs
2. **Use multi-AZ NAT**: Ensures high availability
3. **Enable flow logs**: Critical for security and troubleshooting
4. **Longer retention**: 30-90 days for compliance

## Outputs Reference

All examples expose the same outputs from the VPC module:

```hcl
# VPC
vpc_id
vpc_cidr_block
region
availability_zones

# Subnets
public_subnet_ids
private_app_subnet_ids
private_db_subnet_ids
isolated_subnet_ids

# NAT & Internet Gateway
nat_gateway_ids
nat_gateway_public_ips
internet_gateway_id

# VPC Endpoints
vpc_endpoint_s3_id
vpc_endpoint_interface_ids
vpc_endpoints_security_group_id

# Flow Logs
flow_logs_cloudwatch_log_group_name
```

## Testing

### Validate Configuration

```bash
terraform init
terraform validate
terraform fmt -check
```

### Plan Changes

```bash
terraform plan -out=tfplan
```

### Apply Changes

```bash
terraform apply tfplan
```

### Destroy Resources

```bash
terraform destroy
```

## Troubleshooting

### Issue: "Error creating VPC: VpcLimitExceeded"

**Solution:** Request VPC limit increase via AWS Support or delete unused VPCs.

### Issue: "Error creating NAT Gateway: NatGatewayLimitExceeded"

**Solution:** Request NAT Gateway limit increase or use `single_nat_gateway = true`.

### Issue: Private subnets can't reach internet

**Solution:** Verify `enable_nat_gateway = true` and check route table associations.

### Issue: VPC Endpoint not working

**Solution:** 
- Verify security group allows HTTPS (443) from VPC CIDR
- Ensure `private_dns_enabled = true` for interface endpoints

## Support

For issues or questions:
1. Check the main module [README](../../modules/vpc/README.md)
2. Review the [implementation plan](../../docs/implementation_plan.md)
3. Open an issue in the repository
