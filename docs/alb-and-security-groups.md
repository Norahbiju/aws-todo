# ALB and security groups

## Routing model

The internet-facing Application Load Balancer listens on HTTP port 80 in both public subnets. Its default action forwards to the frontend `ip` target group on port 3000. Priority 100 matches `/api/*` and forwards to backend port 8000. Frontend health uses `/health`; backend health uses `/api/health`; both must return 200 without authentication.

The ALB security group accepts only public TCP 80 and can send only TCP 3000 and 8000 to the ECS security group. The ECS group accepts those ports only when the source is the ALB group. It does not accept the internet or the VPC CIDR. ECS egress remains open because tasks need DNS, HTTPS GHCR pulls, logging, and AWS APIs through NAT.

## Security and operational details

Target type `ip` registers Fargate ENI addresses. A 30-second deregistration delay drains in-flight connections during replacement. Invalid HTTP headers are dropped. Production deletion protection guards the ALB, which means a destroy plan will fail until that deliberate setting is changed and applied through the pipeline.

HTTP is intentionally the no-domain baseline. For real data, add an ACM certificate, an HTTPS listener, and an HTTP redirect before exposing the service; never send credentials over HTTP.

If `/api/*` returns a Next.js 404, inspect listener-rule priority and pattern. If targets remain unhealthy, compare target port, container name, health path, security-group references, and ECS events. Use `aws elbv2 describe-target-health` and test the ALB DNS name. “Listener” receives connections, “rule” selects an action, and “target group” tracks destinations and health.

References: [ALB listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html), [target groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html), [security groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html).

