################################################################################
# VPC
################################################################################

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # IPv6 support
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = local.vpc_tags_merged
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "main" {
  count = var.enable_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # Auto-assign public IPs for instances launched in public subnets
  map_public_ip_on_launch = true

  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
    local.eks_public_subnet_tags,
    {
      Name = "${var.vpc_name}-public-${local.azs[count.index]}"
      Tier = "Public"
    },
    var.public_subnet_tags
  )
}

################################################################################
# Private Application Subnets
################################################################################

resource "aws_subnet" "private_app" {
  count = var.private_app_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_app_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 16) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
    local.eks_private_subnet_tags,
    {
      Name = "${var.vpc_name}-private-app-${local.azs[count.index]}"
      Tier = "PrivateApp"
    },
    var.private_app_subnet_tags
  )
}

################################################################################
# Private Database Subnets
################################################################################

resource "aws_subnet" "private_db" {
  count = var.private_db_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_db_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 32) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-db-${local.azs[count.index]}"
      Tier = "PrivateDB"
    },
    var.private_db_subnet_tags
  )
}

################################################################################
# Isolated Subnets
################################################################################

resource "aws_subnet" "isolated" {
  count = var.isolated_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.isolated_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 48) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-isolated-${local.azs[count.index]}"
      Tier = "Isolated"
    },
    var.isolated_subnet_tags
  )
}

################################################################################
# Elastic IPs for NAT Gateways
################################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-eip-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

################################################################################
# NAT Gateways
################################################################################

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

################################################################################
# Route Tables - Public
################################################################################

resource "aws_route_table" "public" {
  count = var.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-public-rt"
      Tier = "Public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.enable_internet_gateway && var.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count = var.enable_internet_gateway && var.enable_ipv6 && var.public_subnet_count > 0 ? 1 : 0

  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main[0].id
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Route Tables - Private Application
################################################################################

resource "aws_route_table" "private_app" {
  count = var.private_app_subnet_count

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-app-rt-${local.azs[count.index]}"
      Tier = "PrivateApp"
    }
  )
}

resource "aws_route" "private_app_nat_gateway" {
  count = var.enable_nat_gateway ? var.private_app_subnet_count : 0

  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private_app" {
  count = var.private_app_subnet_count

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

################################################################################
# Route Tables - Private Database
################################################################################

resource "aws_route_table" "private_db" {
  count = var.private_db_subnet_count

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-db-rt-${local.azs[count.index]}"
      Tier = "PrivateDB"
    }
  )
}

resource "aws_route" "private_db_nat_gateway" {
  count = var.enable_nat_gateway ? var.private_db_subnet_count : 0

  route_table_id         = aws_route_table.private_db[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private_db" {
  count = var.private_db_subnet_count

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

################################################################################
# Route Tables - Isolated
################################################################################

resource "aws_route_table" "isolated" {
  count = var.isolated_subnet_count

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-isolated-rt-${local.azs[count.index]}"
      Tier = "Isolated"
    }
  )
}

resource "aws_route_table_association" "isolated" {
  count = var.isolated_subnet_count

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated[count.index].id
}

################################################################################
# VPC Flow Logs - CloudWatch
################################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = local.enable_flow_logs_cloudwatch ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.vpc_name}"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_id != "" ? var.flow_logs_kms_key_id : null

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-flow-logs"
    }
  )
}

resource "aws_iam_role" "flow_logs" {
  count = local.enable_flow_logs_cloudwatch ? 1 : 0

  name = "${var.vpc_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.enable_flow_logs_cloudwatch ? 1 : 0

  name = "${var.vpc_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "cloudwatch" {
  count = local.enable_flow_logs_cloudwatch ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = var.flow_logs_traffic_type
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-flow-logs-cloudwatch"
    }
  )
}

################################################################################
# VPC Flow Logs - S3
################################################################################

resource "aws_flow_log" "s3" {
  count = local.enable_flow_logs_s3 ? 1 : 0

  vpc_id               = aws_vpc.main.id
  traffic_type         = var.flow_logs_traffic_type
  log_destination_type = "s3"
  log_destination      = var.flow_logs_s3_bucket_arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-flow-logs-s3"
    }
  )
}

################################################################################
# VPC Endpoints - Gateway (S3 & DynamoDB)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${local.region}.s3"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    aws_route_table.private_db[*].id,
    aws_route_table.isolated[*].id
  )

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${local.region}.dynamodb"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    aws_route_table.private_db[*].id,
    aws_route_table.isolated[*].id
  )

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-dynamodb-endpoint"
    }
  )
}

################################################################################
# VPC Endpoints - Interface Endpoints Security Group
################################################################################

resource "aws_security_group" "vpc_endpoints" {
  count = length(local.enabled_interface_endpoints) > 0 && length(var.vpc_endpoint_security_group_ids) == 0 ? 1 : 0

  name_prefix = "${var.vpc_name}-vpc-endpoints-"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-vpc-endpoints-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# VPC Endpoints - Interface Endpoints
################################################################################

resource "aws_vpc_endpoint" "interface" {
  for_each = local.enabled_interface_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.${each.value.service_name}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private_app[*].id

  security_group_ids = length(var.vpc_endpoint_security_group_ids) > 0 ? var.vpc_endpoint_security_group_ids : [aws_security_group.vpc_endpoints[0].id]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}-endpoint"
    }
  )
}
