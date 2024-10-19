resource "aws_eks_cluster" "coworking_space_eks_cluster" {
  name     = "coworking_space_eks_cluster"
  role_arn = var.coworking_space_eks_cluster_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  bootstrap_self_managed_addons = true

  version = "1.30"

  tags = {
    Name        = "coworking_space_eks_cluster"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
