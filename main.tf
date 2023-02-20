###################################################
# Create Launch template
###################################################

resource "aws_launch_template" "web-farm" {
  name = "web-farm"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }
  
  iam_instance_profile {
	name = "EC2-IAM-role"
  }

  image_id = "ami-0dfcb1ef8550277af"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
    key_name = "terraform-access2"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = ["sg-099d4b722390be85f","sg-075e2970bbd4fe066","sg-2cdd7e2c"]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web server"
    }
  }
  user_data = filebase64("./on-boot.sh")
}

###################################################
# Create Application Load Ballancer
###################################################


resource "aws_lb" "alb-lb-test" {
  name               = "alb-lb-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-075e2970bbd4fe066"]
  subnets            = ["subnet-ef88b2a2","subnet-05e98363","subnet-98d76ea9","subnet-eea68ae0","subnet-c6d6a199","subnet-cb7505ea"]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "alb-lb-tg-test" {
  name        = "alb-lb-tg-test"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-e447c199"
}

resource "aws_lb_listener" "alb-lb-test" {
  load_balancer_arn = aws_lb.alb-lb-test.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-lb-tg-test.arn
  }
}

###################################################
# Create Auto Scaling Group
###################################################


resource "aws_autoscaling_group" "web-farm-asg" {
  availability_zones = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1e","us-east-1f"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  health_check_type  = "ELB"
  target_group_arns   = [aws_lb_target_group.alb-lb-tg-test.arn]

  launch_template {
    id      = aws_launch_template.web-farm.id
    version = "$Latest"
  }
}

###################################################
# Create RDS DB
###################################################


resource "aws_db_instance" "rds_instance" {
  allocated_storage = 20
  identifier = "rds-terraform"
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t2.micro"
  db_name = "mydemodb"
  username = "admin"
  password = ""
  publicly_accessible    = false
  skip_final_snapshot    = true
  auto_minor_version_upgrade = false
  vpc_security_group_ids  = ["sg-2cdd7e2c"]
  tags = {
    Name = "MySQL test db"
  }
}

###################################################
# Create CloudWatch Alarm
###################################################


resource "aws_cloudwatch_metric_alarm" "request-count" {
  alarm_name                = "request-count"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "RequestCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = "120"
  statistic                 = "Maximum"
  threshold                 = "5"
  alarm_description         = "This metric monitors request counts to the ALB"
  insufficient_data_actions = []
}