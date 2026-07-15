resource "aws_iam_role" "execution" {
  name = "${local.name}-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.${data.aws_partition.current.dns_suffix}" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "execution_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = ["${aws_cloudwatch_log_group.frontend.arn}:*", "${aws_cloudwatch_log_group.backend.arn}:*"]
    }]
  })
}

resource "aws_iam_role" "task" {
  name = "${local.name}-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.${data.aws_partition.current.dns_suffix}" }
      Action    = "sts:AssumeRole"
    }]
  })
}

