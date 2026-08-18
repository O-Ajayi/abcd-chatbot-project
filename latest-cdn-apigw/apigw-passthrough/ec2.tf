resource "aws_instance" "app" {
  count = local.create_alb ? 1 : 0

  ami                    = data.aws_ami.amazon_linux_2023[0].id
  instance_type          = var.instance_type
  subnet_id              = local.ec2_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2[0].id]
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    app_port         = var.app_port
    api_route_prefix = var.api_route_prefix
  })

  tags = {
    Name = "${local.name_prefix}-app"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count = local.create_alb ? 1 : 0

  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = aws_instance.app[0].id
  port             = var.app_port
}
