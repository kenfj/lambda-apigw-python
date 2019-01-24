locals {
  name       = "lambda-api-gw"
  stage_name = "dev"
}

######################################################################
# Lambda
######################################################################
resource "aws_lambda_function" "example" {
  function_name    = "${local.name}"
  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role = "${aws_iam_role.lambda_role.arn}"

  handler = "hello_lambda.lambda_handler"
  runtime = "python3.6"

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "../app/hello_lambda.py"
  output_path = "hello_lambda.zip"
}

output "lambda_arn" {
  value = "${aws_lambda_function.example.qualified_arn}"
}

######################################################################
# Lambda IAM
######################################################################
resource "aws_iam_role" "lambda_role" {
  name               = "${local.name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

######################################################################
# API GW
######################################################################
resource "aws_api_gateway_rest_api" "example" {
  name        = "${local.name}"
  description = "Terraform Serverless Application Example"
}

# Resources > root
resource "aws_api_gateway_method" "root" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.root.resource_id}"
  http_method = "${aws_api_gateway_method.root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}

# Resources > /proxy (match any request path)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"

  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}

# Resources > Deploy API
resource "aws_api_gateway_deployment" "example" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "${local.stage_name}"

  depends_on = [
    "aws_api_gateway_integration.root",
    "aws_api_gateway_integration.proxy",
  ]
}

# Stages > Stage Editor > enable CloudWatch Logs
resource "aws_api_gateway_method_settings" "example" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "${local.stage_name}"
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }

  depends_on = [
    "aws_api_gateway_deployment.example",
  ]
}

output "cloudwatch_log_group" {
  value = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.example.id}/${local.stage_name}"
}

######################################################################
# Lambda permission for API GW
######################################################################

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.example.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.example.invoke_url}"
}

######################################################################
# API GW IAM
######################################################################

resource "aws_iam_role" "apigw_role" {
  name               = "${local.name}-APIGatewayLogsRole"
  description        = "Allows API Gateway to push logs to CloudWatch Logs."
  assume_role_policy = "${data.aws_iam_policy_document.apigw_policy.json}"
}

data "aws_iam_policy_document" "apigw_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "apigw_logs_policy" {
  role       = "${aws_iam_role.apigw_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
