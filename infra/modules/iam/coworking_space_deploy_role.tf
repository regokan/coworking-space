# IAM Role for CodeBuild
resource "aws_iam_role" "coworking_space_codebuild_deploy_role" {
  name = "coworking_space_codebuild_deploy_role"
  assume_role_policy = data.aws_iam_policy_document.coworking_space_deploy_assume_role_policy.json

  tags = {
    Name        = "coworking_space_codebuild_deploy_role"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

data "aws_iam_policy_document" "coworking_space_deploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "coworking_space_codebuild_deploy_policy" {
  name = "coworking_space_codebuild_deploy_policy"
  role = aws_iam_role.coworking_space_codebuild_deploy_role.id

  policy = data.aws_iam_policy_document.coworking_space_deploy_access_policy.json
}

data "aws_iam_policy_document" "coworking_space_deploy_access_policy" {
  statement {
    actions = [
      "ecr:*",
      "eks:*",
      "secretsmanager:GetSecretValue",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      var.coworking_space_codepipeline_bucket_arn,                  # Granting access to list the bucket itself
      "${var.coworking_space_codepipeline_bucket_arn}/*"            # Granting access to objects inside the bucket
    ]
  }
}
