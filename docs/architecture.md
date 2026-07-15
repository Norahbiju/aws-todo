# Runtime architecture

## System view

```mermaid
flowchart TB
  User((User)) -->|HTTP :80| ALB[Internet-facing ALB\nSG: public HTTP]
  subgraph VPC[VPC]
    subgraph AZA[Availability Zone A]
      PubA[Public subnet] --> NATA[NAT gateway A]
      PrivA[Private subnet] --> ENIA[ECS task ENI]
    end
    subgraph AZB[Availability Zone B]
      PubB[Public subnet] --> NATB[NAT gateway B]
      PrivB[Private subnet] --> ENIB[ECS task ENI]
    end
    ALB -->|default / :3000| FTG[Frontend target group]
    ALB -->|/api/* :8000| BTG[Backend target group]
    FTG -->|ECS SG from ALB SG only| FE[Next.js container]
    BTG -->|ECS SG from ALB SG only| BE[FastAPI container]
    ENIA --- FE
    ENIA --- BE
    ENIB -. alternate scaled task .- FE
  end
  FE --> CW[CloudWatch Logs]
  BE --> CW
  SSM[SSM image manifest] -->|plan-time jsondecode| ECS[ECS task definition]
  GHCR[Public GHCR\ndigest-pinned images] -->|NAT egress pull| NATA
  GHCR -->|NAT egress pull| NATB
  ECS --> FE
  ECS --> BE
```

The ALB exists in both public subnets. A Fargate task receives an ENI in one private subnet, has no public IP, and contains both essential containers. Public route tables reach the internet gateway. Each private route table reaches its same-AZ NAT gateway by default, providing resilient outbound access to GHCR and AWS APIs.

## Request and deployment connections

The user path is `Internet → ALB → ALB security group → private task ENI → ECS security group → selected container`. Frontend and backend have separate target groups because one task exposes two ports. Target type `ip` is required for Fargate `awsvpc` networking.

The image pipeline writes a single JSON SSM parameter. Terraform reads and validates both digest references during planning, so the saved binary plan contains the exact revisions later applied. CloudWatch receives stdout/stderr and Container Insights metrics.

## Security, failures, and verification

There is no direct task ingress, public IP, database, or registry secret. NAT is egress only. The main availability risk is process-local state and desired count one; autoscaling improves capacity but not state consistency. Verify target health in EC2 target groups, task ENIs in ECS, route tables in VPC, log streams in CloudWatch, and the ALB DNS Terraform output.

References: [AWS ECS networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-networking.html), [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html), [SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html).

