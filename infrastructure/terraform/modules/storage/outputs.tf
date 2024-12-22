output "frontend_bucket_domain" {
  description = "Domain name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "station_list_bucket_id" {
  description = "ID of the station list S3 bucket"
  value       = aws_s3_bucket.station_list.id
}

output "station_list_bucket_arn" {
  description = "ARN of the station list S3 bucket"
  value       = aws_s3_bucket.station_list.arn
}

output "cloudfront_logs_bucket" {
  description = "Name of the S3 bucket for CloudFront logs"
  value       = aws_s3_bucket.cloudfront_logs.id
}

output "dynamodb_table_arns" {
  description = "ARNs of all DynamoDB tables"
  value = [
    aws_dynamodb_table.stations_cache.arn,
    aws_dynamodb_table.tide_predictions_cache.arn
  ]
}
