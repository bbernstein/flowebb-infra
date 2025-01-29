output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "route53_zone_id" {
  description = "ID of the Route53 zone"
  value       = data.aws_route53_zone.main.zone_id
}
