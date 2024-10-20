# CodeBuild Project for EKS Deployment
resource "aws_codebuild_project" "coworking_space_deploy" {
  name          = "coworking_app_deploy"
  service_role  = var.coworking_space_codebuild_deploy_role_arn

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = var.coworking_space_eks_cluster_name
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.coworking_space_api_repository_url
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/regokan/repository"
    buildspec = "buildspec-deploy.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}
