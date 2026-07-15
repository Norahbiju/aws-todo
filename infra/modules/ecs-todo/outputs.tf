output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.this.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "vpc_id" {
  description = "Application VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB and NAT gateways."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS tasks."
  value       = aws_subnet.private[*].id
}

output "image_manifest_git_sha" {
  description = "Git SHA recorded by the image-manifest workflow."
  value       = try(local.image_manifest.git_sha, null)
}

