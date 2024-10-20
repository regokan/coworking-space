output "coworking_space_eks_cluster_role_arn" {
  value = aws_iam_role.coworking_space_eks_role.arn
}

output "coworking_space_node_group_role_arn" {
  value = aws_iam_role.coworking_space_node_group_role.arn
}

output "coworking_space_eks_role_policy_attachment" {
  value = aws_iam_role_policy_attachment.coworking_space_eks_role_policy_attachment.id
}

output "coworking_space_eks_role_vpc_resource_controller_policy_attachment" {
  value = aws_iam_role_policy_attachment.coworking_space_eks_role_vpc_resource_controller_policy_attachment.id
}

output "coworking_space_codebuild_role_arn" {
  value = aws_iam_role.coworking_space_codebuild_role.arn
}

output "coworking_space_codebuild_deploy_role_arn" {
  value = aws_iam_role.coworking_space_codebuild_deploy_role.arn
}

output "coworking_space_codepipeline_role_arn" {
  value = aws_iam_role.coworking_space_codepipeline_role.arn
}
