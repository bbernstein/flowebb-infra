# First create API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.frontend_domain}"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
  }
}

# Create CloudWatch log groups before Lambda functions
resource "aws_cloudwatch_log_group" "lambda_tides" {
  name              = "/aws/lambda/${var.project_name}-tides-${var.environment}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "lambda_stations" {
  name              = "/aws/lambda/${var.project_name}-stations-${var.environment}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
}

# Create Lambda functions
resource "aws_lambda_function" "tides" {
  filename         = var.lambda_jar_path
  source_code_hash = var.lambda_jar_hash
  function_name    = "${var.project_name}-tides-${var.environment}"
  role            = var.lambda_role_arn
  handler         = "com.flowebb.lambda.TidesLambda::handleRequest"
  runtime         = "java11"
  memory_size     = var.lambda_memory_size
  timeout         = var.lambda_timeout

  environment {
    variables = {
      STATION_LIST_BUCKET = var.station_list_bucket_id
      ALLOWED_ORIGINS    = "https://${var.frontend_domain}"
      LOG_LEVEL         = "DEBUG"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_tides]
}

resource "aws_lambda_function" "stations" {
  filename         = var.lambda_jar_path
  source_code_hash = var.lambda_jar_hash
  function_name    = "${var.project_name}-stations-${var.environment}"
  role            = var.lambda_role_arn
  handler         = "com.flowebb.lambda.StationsLambda::handleRequest"
  runtime         = "java11"
  memory_size     = var.lambda_memory_size
  timeout         = var.lambda_timeout

  environment {
    variables = {
      STATION_LIST_BUCKET = var.station_list_bucket_id
      ALLOWED_ORIGINS    = "https://${var.frontend_domain}"
      LOG_LEVEL         = "DEBUG"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_stations]
}

# Create API Gateway integrations
resource "aws_apigatewayv2_integration" "tides" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.tides.invoke_arn

  depends_on = [aws_lambda_function.tides]
}

resource "aws_apigatewayv2_integration" "stations" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.stations.invoke_arn

  depends_on = [aws_lambda_function.stations]
}

# Create routes
resource "aws_apigatewayv2_route" "tides" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/tides"
  target    = "integrations/${aws_apigatewayv2_integration.tides.id}"

  depends_on = [aws_apigatewayv2_integration.tides]
}

resource "aws_apigatewayv2_route" "stations" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/stations"
  target    = "integrations/${aws_apigatewayv2_integration.stations.id}"

  depends_on = [aws_apigatewayv2_integration.stations]
}

# Create API Gateway stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      resourcePath  = "$context.resourcePath"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [aws_cloudwatch_log_group.api_logs]
}

# Create Lambda permissions
resource "aws_lambda_permission" "api_gw_tides" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tides.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_stations" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stations.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Create CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "Errors"
  namespace          = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Lambda function error rate"

  dimensions = {
    FunctionName = aws_lambda_function.tides.function_name
  }
}
