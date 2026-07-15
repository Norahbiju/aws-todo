# AWS networking

## What is created and why

Each account gets one IPv4 VPC, two public subnets, two private subnets, an internet gateway, two Elastic IPs, and two NAT gateways. Subnets span the first two deterministically sorted available AZs unless an explicit pair is supplied. Account-specific AZ names are not hardcoded because the same AZ letter can represent different physical zones across accounts.

The ALB and NAT gateways use public subnets. ECS task ENIs use only private subnets with `assign_public_ip=false`. Public `0.0.0.0/0` routes point at the internet gateway; each private default route points to the NAT in the same AZ. DNS support and hostnames are enabled so containers can resolve GHCR, CloudWatch, and AWS endpoints.

CIDRs are isolated: dev `10.10.0.0/16`, staging `10.20.0.0/16`, and prod `10.30.0.0/16`. Change them before deployment if they overlap corporate, VPN, transit gateway, or peered ranges.

## Security, failures, and verification

NAT does not allow unsolicited inbound traffic. Network access is additionally controlled by security groups. A route table without a NAT route, exhausted NAT ports, DNS failure, or unavailable public GHCR prevents image pulls. Check subnet associations, EIP/NAT state, network ACLs, VPC DNS attributes, and ECS stopped-task reasons.

Use `aws ec2 describe-route-tables`, VPC Reachability Analyzer, and NAT CloudWatch metrics for read-only verification. “AZ” is an isolated regional location, “ENI” a virtual network interface, and “CIDR” an address range.

Two NAT gateways are the high-availability default and generate hourly plus data-processing charges. `nat_gateway_count=1` is an explicit non-production cost option; it creates a cross-AZ dependency and possible cross-AZ charges. Production remains at two.

References: [VPC design](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html), [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html), [Route tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html).

