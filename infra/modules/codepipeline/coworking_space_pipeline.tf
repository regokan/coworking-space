resource "aws_codepipeline" "coworking_space_coworking_pipeline" {
  name     = "coworking_space_coworking_pipeline"
  role_arn = var.coworking_space_codepipeline_role_arn

  artifact_store {
    location = var.coworking_space_codepipeline_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name            = "Source"
      category        = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn =  var.github_connection_arn
        FullRepositoryId = "regokan/coworking-space"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.coworking_space_build_name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.coworking_space_deploy_name
      }
    }
  }

  tags = {
    Name        = "coworking_space_coworking_pipeline"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
