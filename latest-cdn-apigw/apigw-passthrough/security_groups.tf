resource "aws_security_group" "vpc_link" {
  name        = "${local.name_prefix}-vpc-link"
  description = "Security group for API Gateway VPC link ENIs"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-vpc-link"
  }
}

resource "aws_security_group" "alb" {
  count = local.create_network ? 1 : 0

  name        = "${local.name_prefix}-alb"
  description = "Security group for internal ALB"
  vpc_id      = local.vpc_id

  ingress {
    description     = "HTTP from API Gateway VPC link"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_link.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_security_group" "ec2" {
  count = local.create_network ? 1 : 0

  name        = "${local.name_prefix}-ec2"
  description = "Security group for sample application EC2 instance"
  vpc_id      = local.vpc_id

  ingress {
    description     = "App traffic from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

resource "aws_security_group_rule" "existing_alb_ingress_from_vpc_link" {
  for_each = local.use_existing_network ? toset(var.existing_alb_security_group_ids) : toset([])

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = each.value
  source_security_group_id = aws_security_group.vpc_link.id
  description              = "HTTP from API Gateway VPC link"
}
