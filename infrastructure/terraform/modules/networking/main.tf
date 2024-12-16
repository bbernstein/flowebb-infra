terraform {
  required_providers {
    aws = {
      configuration_aliases = [ aws.us-east-1 ]
    }
  }
}

data "aws_route53_zone" "main" {
  name = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "main" {
  provider          = aws.us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}",
    var.frontend_domain,
    var.api_domain
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-certificate"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy      = true
    ignore_changes      = [
      validation_option,
      validation_method
    ]
  }
}

locals {
  # Create a map of unique records based on the record name
  distinct_domain_validations = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if !contains(
      [for v in tolist(aws_acm_certificate.main.domain_validation_options) : v.resource_record_name],
      dvo.resource_record_name
    )
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.distinct_domain_validations

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "access-identity-${var.frontend_domain}"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled    = true
  default_root_object = "index.html"
  aliases            = [var.frontend_domain, var.api_domain]

  origin {
    domain_name = var.frontend_bucket_domain
    origin_id   = "frontend"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = var.api_gateway_hostname
    origin_id   = "api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  logging_config {
    include_cookies = true
    bucket         = "${var.cloudfront_logs_bucket}.s3.amazonaws.com"
    prefix         = "cloudfront/"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.frontend_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      zone_id,
      allow_overwrite,
      multivalue_answer_routing_policy
    ]
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      zone_id,
      allow_overwrite,
      multivalue_answer_routing_policy
    ]
  }
}

# Allow CloudFront to access the S3 bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.frontend_domain

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.frontend_bucket_arn}/*"
      }
    ]
  })
}
