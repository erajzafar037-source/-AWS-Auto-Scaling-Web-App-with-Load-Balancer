variable "name" {}
variable "vpc_id" {}
variable "subnets" { type = list(string) }
variable "alb_sg_id" {}
variable "target_group_arn" {}
variable "instance_type" {}
variable "ami_id" {}
variable "app_version" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_size" {}
variable "alb_resource_label" {}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.al2023.value
}

# ---- IAM: no static keys on instances ----
resource "aws_iam_role" "ec2" {
  name_prefix = "${var.name}-ec2-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.name}-"
  role        = aws_iam_role.ec2.name
}

resource "aws_security_group" "ec2" {
  name_prefix = "${var.name}-ec2-"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id] # only the ALB can reach instances
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-lt-"
  image_id               = local.ami
  instance_type          = var.instance_type
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  metadata_options {
    http_tokens = "required" # IMDSv2
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    app_version = var.app_version
    use_baked   = var.ami_id != ""
  }))
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-web", Version = var.app_version }
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-asg-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_size
  vpc_zone_identifier       = var.subnets
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  # Zero-downtime rolling deployment: a new launch template version triggers an instance refresh.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100 # never drop below current capacity
      max_healthy_percentage = 200 # launch new before terminating old
      instance_warmup        = 90
    }
  }

  enabled_metrics = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]

  lifecycle { create_before_destroy = true }
}

# Target tracking = production-friendly equivalent of "scale out ~70% / in ~30%".
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

resource "aws_autoscaling_policy" "requests" {
  name                   = "${var.name}-req-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_resource_label
    }
    target_value = 500
  }
}

output "asg_name" { value = aws_autoscaling_group.this.name }
