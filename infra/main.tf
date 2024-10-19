terraform {
  backend "s3" {
    bucket = "coworking-space-api-tf-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source = "./modules/eks"

  subnet_ids = [aws_subnet.coworking_space_subnet1.id, aws_subnet.coworking_space_subnet2.id]
  coworking_space_eks_cluster_role_arn = module.iam.coworking_space_eks_cluster_role_arn
  coworking_space_node_group_role_arn = module.iam.coworking_space_node_group_role_arn
}
