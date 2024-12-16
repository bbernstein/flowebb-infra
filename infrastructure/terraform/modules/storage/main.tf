resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_domain
}

resource "aws_s3_bucket" "station_list" {
  bucket = "${var.project_name}-station-list-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "station_list" {
  bucket = aws_s3_bucket.station_list.id

  rule {
    id     = "delete_old_files"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_dynamodb_table" "stations_cache" {
  name           = "stations-cache"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "stationId"

  attribute {
    name = "stationId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "harmonic_constants_cache" {
  name           = "harmonic-constants-cache"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "stationId"

  attribute {
    name = "stationId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# Add S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.project_name}-cloudfront-logs-${var.environment}"
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"
}
