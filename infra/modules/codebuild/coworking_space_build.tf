# CodeBuild Project
resource "aws_codebuild_project" "coworking_space_build" {
  name         = "coworking_app_build"
  service_role = var.coworking_space_codebuild_role_arn

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_REGION"
      value = "us-east-1"
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/regokan/coworking-space"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}
