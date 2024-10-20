output "coworking_space_build_name" {
  value = aws_codebuild_project.coworking_space_build.name
}

output "coworking_space_deploy_name" {
  value = aws_codebuild_project.coworking_space_deploy.name
}
