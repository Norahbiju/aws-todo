# Cost considerations

## Baseline cost drivers

The dominant fixed cost is usually two NAT gateways per account, plus NAT data processing for GHCR pulls and API traffic. Other metered components are the Application Load Balancer and LCUs, Fargate vCPU/memory runtime, CloudWatch Logs ingestion/storage, Container Insights custom metrics, three alarms, public IPv4/EIPs, S3 state requests/storage, optional KMS requests, and internet or cross-account transfer.

Three accounts multiply the baseline even when traffic is low. Prices vary by region and date, so use the [AWS Pricing Calculator](https://calculator.aws/) and current service pricing before deployment. Set budgets and anomaly detection in every account; tag costs by project/environment.

## Explicit cost-optimised option

For an accepted non-production availability trade-off, set `nat_gateway_count=1` in the relevant Terragrunt child. Both private subnets then depend on one AZ's NAT and traffic from the other AZ can incur cross-AZ charges. This is not the default, and production stays at two. Other options include scheduled dev destruction through the controlled pipeline, lower log retention, and VPC endpoints after comparing endpoint hourly charges with NAT traffic.

Do not optimise by giving tasks public IPs, making task ports public, disabling logs/alarms without an operational replacement, or using mutable images. Review destroy plans carefully: prod ALB deletion protection must be deliberately disabled by a reviewed apply before final destruction.

## Verification

Use Cost Explorer grouped by tags/service, NAT gateway metrics, ALB consumed LCUs, Fargate running hours, and CloudWatch usage. Common surprises are idle NAT/ALB hourly charges, repeated image-pull data, verbose logs, Container Insights metrics, and cross-AZ routing.

References: [NAT pricing](https://aws.amazon.com/vpc/pricing/), [Fargate pricing](https://aws.amazon.com/fargate/pricing/), [ALB pricing](https://aws.amazon.com/elasticloadbalancing/pricing/), [CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/).
