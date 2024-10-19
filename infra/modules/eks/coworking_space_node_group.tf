resource "aws_eks_node_group" "coworking_space_node_group" {
  cluster_name    = aws_eks_cluster.coworking_space_eks_cluster.name
  node_group_name = "coworking-space-node-group"
  node_role_arn   = var.coworking_space_node_group_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  depends_on = [aws_eks_cluster.coworking_space_eks_cluster]

  tags = {
    Name        = "coworking_space_node_group"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
