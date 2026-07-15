# ECS Fargate

## What, why, and how

Amazon ECS schedules containers; Fargate supplies serverless task compute. The module creates one cluster with Container Insights, one service, and one task definition with `awsvpc`, `FARGATE`, Linux, and x86_64. The default 512 CPU units and 1,024 MiB are split evenly between the two essential containers.

The execution role can only create log streams and put log events in the two application groups. Public GHCR pulls need no registry credential. The separate task role has no policy because the application calls no AWS API. Adding application AWS access must use narrowly scoped task-role permissions, never the execution role.

The service starts at one task in private subnets, registers frontend port 3000 and backend port 8000, rolls between 50% and 200% capacity, uses a deployment circuit breaker with rollback, grants 90 seconds for health, and waits for steady state. Both containers are essential: failure of either makes the combined task unhealthy.

## Connections, failures, and verification

ECS obtains exact images from the task definition, sends stdout to CloudWatch, attaches task ENIs to the ECS security group, and registers container ports with both target groups. Health checks occur inside each container and from the ALB.

Common failures are `CannotPullContainerError` (private GHCR, bad digest, NAT/DNS), `ResourceInitializationError` (logs or IAM), health-check failures (wrong path/port/start period), and failure to register both containers (name/port mismatch). Inspect ECS service events, stopped reasons, target health descriptions, and both log groups. `aws ecs wait services-stable` is used after approved apply.

References: [Fargate task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-defs.html), [ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html), [deployment circuit breaker](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-circuit-breaker.html).

