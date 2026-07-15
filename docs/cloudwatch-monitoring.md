# CloudWatch monitoring

## Logs, metrics, and alarms

Each container writes structured stdout/stderr to its own `/ecs/<project>-<environment>/<container>` log group through `awslogs`. Retention is 14 days in dev, 30 in staging, and 90 in prod. ECS Container Insights is enabled so task/service metrics include `RunningTaskCount`.

Three one-minute alarms are created:

| Alarm | Metric | Meaning |
|---|---|---|
| Running tasks | `ECS/ContainerInsights RunningTaskCount`, Minimum < 1 | no service task observed; missing data is breaching |
| ALB 5xx | `AWS/ApplicationELB HTTPCode_ELB_5XX_Count`, Sum > 10 | load balancer itself generated errors |
| Target 5xx | `AWS/ApplicationELB HTTPCode_Target_5XX_Count`, Sum > 10 | application targets returned errors |

The ALB dimension uses its ARN suffix. An optional existing SNS topic can receive ALARM and OK actions. Subscription and escalation ownership remain outside this module.

## Security, failures, and verification

Logs may contain user-provided titles and descriptions; control access, retention, exports, and query permissions. Application logs intentionally omit credentials and stack traces from client responses, but server exceptions remain visible to operators.

“Insufficient data” on running tasks usually means Container Insights is disabled, dimensions are wrong, or the service has not emitted yet. Missing data is deliberately treated as breaching for availability. Check cluster settings, exact service/cluster names, metric region, task execution role log permission, log group names, and alarm history.

References: [Container Insights ECS metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-ECS.html), [ALB metrics](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html), [alarm missing data](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html).

