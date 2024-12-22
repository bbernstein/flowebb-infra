resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_domain
}

# Add versioning for deployment management
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure proper CORS for the frontend bucket
resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${var.frontend_domain}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# Ensure objects are accessible via CloudFront
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

resource "aws_dynamodb_table" "tide_predictions_cache" {
  name           = "tide-predictions-cache"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "stationId"
  range_key      = "date"

  attribute {
    name = "stationId"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "tide-predictions-cache"
    Environment = var.environment
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
