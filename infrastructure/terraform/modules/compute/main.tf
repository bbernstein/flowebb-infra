resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.frontend_domain}"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
  }
}

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
      integration = {
        error = "$context.integration.error"
        integrationStatus = "$context.integration.status"
        latency = "$context.integration.latency"
        requestId = "$context.integration.requestId"
      }
    })
  }
}

# Create CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 30
}

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "../../../../backend/build/libs/tides-be.jar"
#   output_path = "lambda.zip"
# }

resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.root}/../../../../backend && ./gradlew build"
  }
}

resource "aws_lambda_function" "tides" {
  filename         = "${path.root}/../../../../backend/build/libs/tides-be.jar"
  source_code_hash = filebase64sha256("${path.root}/../../../../backend/build/libs/tides-be.jar")
  function_name    = "${var.project_name}-tides-${var.environment}"
  role            = var.lambda_role_arn
  handler         = "com.flowebb.lambda.TidesLambda::handleRequest"
  runtime         = "java11"
  memory_size     = 512
  timeout         = 120

  depends_on = [null_resource.build_lambda]

  environment {
    variables = {
      STATION_LIST_BUCKET = var.station_list_bucket_id
      ALLOWED_ORIGINS    = "https://${var.frontend_domain}"
      LOG_LEVEL          = "DEBUG"
    }
  }

}

resource "aws_lambda_function" "stations" {
  filename         = "${path.root}/../../../../backend/build/libs/tides-be.jar"
  source_code_hash = filebase64sha256("${path.root}/../../../../backend/build/libs/tides-be.jar")
  function_name    = "${var.project_name}-stations-${var.environment}"
  role            = var.lambda_role_arn
  handler         = "com.flowebb.lambda.StationsLambda::handleRequest"
  runtime         = "java11"
  memory_size     = 512
  timeout         = 120

  depends_on = [null_resource.build_lambda]

  environment {
    variables = {
      STATION_LIST_BUCKET = var.station_list_bucket_id
      ALLOWED_ORIGINS    = "https://${var.frontend_domain}"
      LOG_LEVEL          = "DEBUG"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_tides" {
  name              = "/aws/lambda/${aws_lambda_function.tides.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "lambda_stations" {
  name              = "/aws/lambda/${aws_lambda_function.stations.function_name}"
  retention_in_days = var.log_retention_days
}

# Add CloudWatch Metric Alarms
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
  alarm_actions      = [] # Add SNS topic ARN here if you want notifications

  dimensions = {
    FunctionName = aws_lambda_function.tides.function_name
  }
}

resource "aws_apigatewayv2_integration" "tides" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.tides.invoke_arn
}

resource "aws_apigatewayv2_integration" "stations" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.stations.invoke_arn
}

resource "aws_apigatewayv2_route" "tides" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/tides"
  target    = "integrations/${aws_apigatewayv2_integration.tides.id}"
}

resource "aws_apigatewayv2_route" "stations" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/stations"
  target    = "integrations/${aws_apigatewayv2_integration.stations.id}"
}

# Add permissions for API Gateway to invoke the Tides Lambda
resource "aws_lambda_permission" "api_gw_tides" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tides.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Add permissions for API Gateway to invoke the Stations Lambda
resource "aws_lambda_permission" "api_gw_stations" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stations.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
