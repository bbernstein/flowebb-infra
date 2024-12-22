data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:GetBucketPolicy",
            "s3:PutBucketPolicy",
            "s3:CreateBucket",
            "s3:DeleteBucket",
            "s3:HeadBucket",
            "s3:GetBucketVersioning",
            "s3:PutBucketVersioning",
            "s3:GetBucketAcl",
            "s3:PutBucketAcl",
            "s3:GetBucketCORS",
            "s3:PutBucketCORS",
            "s3:GetBucketWebsite",
            "s3:PutBucketWebsite",
            "s3:DeleteBucketWebsite",
            "s3:GetBucketTagging",
            "s3:PutBucketTagging",
            "s3:GetBucketLogging",
            "s3:PutBucketLogging",
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketRequestPayment",
            "s3:GetLifecycleConfiguration",
            "s3:PutLifecycleConfiguration",
            "s3:DeleteBucketLifecycle",
            "s3:GetReplicationConfiguration",
            "s3:PutReplicationConfiguration",
            "s3:DeleteBucketReplication",
            "s3:GetBucketObjectLockConfiguration",
            "s3:GetEncryptionConfiguration",
            "s3:PutEncryptionConfiguration",
            "s3:GetBucketPublicAccessBlock",
            "s3:PutBucketPublicAccessBlock",
            "s3:GetBucketLocation",
            "s3:GetBucketOwnershipControls",
            "s3:PutBucketOwnershipControls"
          ]
          Resource = [
            "${var.frontend_bucket_arn}/*",
            var.frontend_bucket_arn,
            "arn:aws:s3:::${var.terraform_state_bucket}/*",
            "arn:aws:s3:::${var.terraform_state_bucket}",
            "arn:aws:s3:::${var.project_name}-station-list-${var.environment}",
            "arn:aws:s3:::${var.project_name}-station-list-${var.environment}/*",
            "arn:aws:s3:::${var.project_name}-cloudfront-logs-${var.environment}",
            "arn:aws:s3:::${var.project_name}-cloudfront-logs-${var.environment}/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:DescribeTable",
            "dynamodb:CreateTable",
            "dynamodb:DeleteTable",
            "dynamodb:UpdateTable",
            "dynamodb:ListTables",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:UpdateContinuousBackups",
            "dynamodb:ListTagsOfResource",
            "dynamodb:TagResource",
            "dynamodb:UntagResource",
            "dynamodb:DescribeTimeToLive"
          ],
          "Resource" : [
            "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.terraform_state_lock_table}",
            "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/stations-cache",
            "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/tide_predictions_cache"
          ]
        },
        {
          "Effect" : "Allow",
            "Action" : [
              "route53:ListHostedZones",
              "route53:GetHostedZone",
              "route53:ListResourceRecordSets",
              "route53:ChangeResourceRecordSets",
              "route53:ListTagsForResource",
              "route53:GetTagsForResource",
              "route53:ChangeTagsForResource"
            ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "acm:RequestCertificate",
            "acm:DescribeCertificate",
            "acm:DeleteCertificate",
            "acm:ListCertificates",
            "acm:ListTagsForCertificate",
            "acm:AddTagsToCertificate",
            "acm:RemoveTagsFromCertificate"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudfront:CreateInvalidation",
            "cloudfront:GetInvalidation",
            "cloudfront:ListInvalidations",
            "cloudfront:CreateDistribution",
            "cloudfront:DeleteDistribution",
            "cloudfront:GetDistribution",
            "cloudfront:UpdateDistribution",
            "cloudfront:TagResource",
            "cloudfront:UntagResource",
            "cloudfront:ListTagsForResource",
            "cloudfront:CreateCloudFrontOriginAccessIdentity",
            "cloudfront:DeleteCloudFrontOriginAccessIdentity",
            "cloudfront:GetCloudFrontOriginAccessIdentity",
            "cloudfront:GetCloudFrontOriginAccessIdentityConfig",
            "cloudfront:UpdateCloudFrontOriginAccessIdentity"
          ],
          Resource = [
            "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}",
            "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-identity/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "lambda:UpdateFunctionCode",
            "lambda:GetFunction",
            "lambda:CreateFunction",
            "lambda:DeleteFunction",
            "lambda:UpdateFunctionConfiguration",
            "lambda:GetFunctionConfiguration",
            "lambda:ListTags",
            "lambda:TagResource",
            "lambda:UntagResource",
            "lambda:ListVersionsByFunction",
            "lambda:PublishVersion",
            "lambda:CreateAlias",
            "lambda:DeleteAlias",
            "lambda:UpdateAlias",
            "lambda:GetAlias",
            "lambda:ListAliases",
            "lambda:GetFunctionCodeSigningConfig",
            "lambda:PutFunctionCodeSigningConfig",
            "lambda:DeleteFunctionCodeSigningConfig",
            "lambda:ListFunctionsByCodeSigningConfig",
            "lambda:GetPolicy",
          ]
          Resource = [
            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-tides-${var.environment}",
            "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-stations-${var.environment}"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "iam:GetRole",
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:PutRolePolicy",
            "iam:GetRolePolicy",
            "iam:DeleteRolePolicy",
            "iam:ListRolePolicies",
            "iam:ListAttachedRolePolicies",
            "iam:AttachRolePolicy",
            "iam:DetachRolePolicy",
            "iam:UpdateRole",
            "iam:UpdateRoleDescription",
            "iam:ListInstanceProfilesForRole",
            "iam:PassRole",
            "iam:CreateOpenIDConnectProvider",
            "iam:DeleteOpenIDConnectProvider",
            "iam:GetOpenIDConnectProvider",
            "iam:UpdateOpenIDConnectProviderThumbprint",
            "iam:AddClientIDToOpenIDConnectProvider",
            "iam:RemoveClientIDFromOpenIDConnectProvider"
          ]
          Resource = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-lambda-role-${var.environment}",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-github-actions-${var.environment}",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "iam:ListOpenIDConnectProviders",
            "iam:ListOpenIDConnectProviderTags",
            "iam:ListRoles"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "apigateway:GET",
            "apigateway:POST",
            "apigateway:PUT",
            "apigateway:DELETE",
            "apigateway:PATCH",
            "apigateway:UpdateRestApiPolicy"
          ]
          Resource = [
            "arn:aws:apigateway:${data.aws_region.current.name}::/apis/*",
            "arn:aws:apigateway:${data.aws_region.current.name}::/apis"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DeleteLogGroup",
            "logs:DeleteLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutRetentionPolicy",
            "logs:GetLogEvents",
            "logs:ListTagsForResource",
            "logs:ListTagsLogGroup",
            "logs:UntagLogGroup",
            "logs:TagLogGroup",
            "logs:TagResource",
            "logs:UntagResource"
          ]
          Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-tides-${var.environment}*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-stations-${var.environment}*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${var.project_name}-${var.environment}*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "cloudwatch:PutMetricData",
            "cloudwatch:EnableAlarmActions",
            "cloudwatch:DisableAlarmActions",
            "cloudwatch:ListTagsForResource",
            "cloudwatch:TagResource",
            "cloudwatch:UntagResource"
          ]
          Resource = [
            "arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:${var.project_name}-${var.environment}-*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [ "sts.amazonaws.com" ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}
