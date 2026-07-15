# ECS service autoscaling

## Behaviour

Application Auto Scaling manages `ecs:service:DesiredCount` from one through four tasks. A target-tracking policy watches `ECSServiceAverageCPUUtilization` and attempts to keep average CPU near 60%. Scale-out cooldown is 60 seconds for responsiveness; scale-in waits 300 seconds to avoid oscillation. Terraform ignores subsequent desired-count drift because the autoscaler owns it.

Each task contains both frontend and backend, so they always scale together even if only one container drives CPU. This keeps routing registration aligned but is less efficient than independent services. Target tracking is not an instant threshold: metrics, evaluation, scheduling, image pulls, and health checks all add delay.

## State warning and verification

Every scaled backend has its own memory. The ALB can send sequential requests to different tasks, producing different Todo sets. A real application needs shared durable state plus concurrency semantics—DynamoDB conditional writes, an SQL transaction, or an equivalent service.

Verify the scalable target and policy in Application Auto Scaling, desired/running counts in ECS, service average CPU in CloudWatch, and scaling activities for denied quotas or cooldown. Load testing must be authorised and cost controlled. If scale-out does not occur, check sustained metric value, minimum/maximum, cooldown, ECS quotas, subnet IPs, and task health.

References: [ECS target tracking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html), [service auto scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html).

