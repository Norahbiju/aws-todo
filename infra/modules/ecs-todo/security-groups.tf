resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Internet traffic to the public ALB"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${local.name}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Public HTTP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs"
  description = "Traffic from the ALB to private ECS task ENIs"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${local.name}-ecs" }
}

resource "aws_vpc_security_group_egress_rule" "alb_frontend" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Frontend target traffic"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_backend" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Backend target traffic"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_frontend" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Frontend traffic only from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_backend" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Backend traffic only from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs.id
  description       = "GHCR, DNS, CloudWatch, and AWS APIs through NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

