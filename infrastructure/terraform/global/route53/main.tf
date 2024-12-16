resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Environment = "global"
    Project     = var.project_name
  }
}
