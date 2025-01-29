output "api_gateway_endpoint" {
  description = "The URL of the API Gateway endpoint"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_hostname" {
  description = "The hostname of the API Gateway"
  value       = replace(aws_apigatewayv2_api.main.api_endpoint, "/^https?://([^/]*).*/", "$1")
}
