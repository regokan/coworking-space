resource "aws_codepipeline" "coworking_space_coworking_pipeline" {
  name     = "coworking_space_coworking_pipeline"
  role_arn = var.coworking_space_codepipeline_role_arn
  pipeline_type = "V2"

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

  trigger {
    provider_type = "CodeStarSourceConnection"

    git_configuration {
      source_action_name = "Source"

      # Trigger on push events
      push {
        branches {
          includes = ["main"]  # Trigger on pushes to these branches
        }

        file_paths {
          includes = ["analytics/*"]  # Trigger only if files in src/ or config/ are changed
          excludes = ["deployment/*"]       # Exclude changes in the docs/ directory
        }
      }

      pull_request {
        events = ["OPEN"]

        branches {
          includes = ["feature*"]  # Filter PRs only targeting these branches
        }

        file_paths {
          includes = ["analytics/*",]  # Trigger on PRs that change files in these paths
        }
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
