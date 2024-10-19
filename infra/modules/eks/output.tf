output "eks_cluster_endpoint" {
  value = aws_eks_cluster.coworking_space_eks_cluster.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.coworking_space_eks_cluster.name
}

output "eks_cluster_version" {
  value = aws_eks_cluster.coworking_space_eks_cluster.version
}

output "eks_node_group_name" {
  value = aws_eks_node_group.coworking_space_node_group.node_group_name
}
