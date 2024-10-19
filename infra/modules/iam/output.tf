output "coworking_space_eks_cluster_role_arn" {
  value = aws_iam_role.coworking_space_eks_role.arn
}

output "coworking_space_node_group_role_arn" {
  value = aws_iam_role.coworking_space_node_group_role.arn
}
