# IAM Role for CodePipeline
resource "aws_iam_role" "coworking_space_codepipeline_role" {
  name               = "coworking_space_codepipeline_role"
  assume_role_policy = data.aws_iam_policy_document.coworking_space_pipeline_assume_role_policy.json

  tags = {
    Name        = "coworking_space_codepipeline_role"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

data "aws_iam_policy_document" "coworking_space_pipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "coworking_space_codepipeline_policy" {
  name = "coworking_space_codepipeline_policy"
  role = aws_iam_role.coworking_space_codepipeline_role.id

  policy = data.aws_iam_policy_document.coworking_space_pipeline_access_policy.json
}

# Policy document allowing S3 access for artifacts
data "aws_iam_policy_document" "coworking_space_pipeline_s3_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectVersion",
      "s3:GetBucketLocation",
    ]
    resources = [
      "${var.coworking_space_codepipeline_bucket_arn}",   # Granting access to list the bucket itself
      "${var.coworking_space_codepipeline_bucket_arn}/*", # Granting access to objects inside the bucket
    ]
  }
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "coworking_space_codepipeline_s3_policy" {
  name   = "coworking_space_codepipeline_s3_policy"
  role   = aws_iam_role.coworking_space_codepipeline_role.id
  policy = data.aws_iam_policy_document.coworking_space_pipeline_s3_policy.json
}

data "aws_iam_policy_document" "coworking_space_pipeline_access_policy" {
  statement {
    actions = [
      "ecr:*",
      "eks:*",
      "codebuild:*",
      "codedeploy:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codestar_connections_policy" {
  name        = "coworking_space_codestar_connections_policy"
  description = "Allow CodePipeline to use CodeStar connection for GitHub"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_attach" {
  role       = aws_iam_role.coworking_space_codepipeline_role.name
  policy_arn = aws_iam_policy.codestar_connections_policy.arn
}
