terraform {
  backend "s3" {
    bucket = "coworking-space-api-tf-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "iam" {
  source = "./modules/iam"

  coworking_space_codepipeline_bucket_arn=module.s3.coworking_space_codepipeline_bucket_arn
}

module "eks" {
  source = "./modules/eks"

  subnet_ids = [aws_subnet.coworking_space_subnet1.id, aws_subnet.coworking_space_subnet2.id]
  coworking_space_eks_cluster_role_arn = module.iam.coworking_space_eks_cluster_role_arn
  coworking_space_node_group_role_arn = module.iam.coworking_space_node_group_role_arn
  coworking_space_eks_role_policy_attachment = module.iam.coworking_space_eks_role_policy_attachment
  coworking_space_eks_role_vpc_resource_controller_policy_attachment = module.iam.coworking_space_eks_role_vpc_resource_controller_policy_attachment
}

module "secretsmanager" {
  source = "./modules/secretsmanager"
}

module "ecr" {
  source = "./modules/ecr"
}

module "codebuild" {
  source = "./modules/codebuild"

  coworking_space_codebuild_role_arn=module.iam.coworking_space_codebuild_role_arn
  coworking_space_codebuild_deploy_role_arn=module.iam.coworking_space_codebuild_deploy_role_arn
  coworking_space_api_repository_url=module.ecr.coworking_space_api_repository_url
  coworking_space_eks_cluster_name=module.eks.eks_cluster_name
  aws_region=data.aws_region.current.name
}

module "s3" {
  source = "./modules/s3"
}

module "codestar" {
  source = "./modules/codestar"
}

module "codepipeline" {
  source = "./modules/codepipeline"

  coworking_space_codepipeline_bucket=module.s3.coworking_space_codepipeline_bucket 
  coworking_space_build_name = module.codebuild.coworking_space_build_name
  coworking_space_deploy_name = module.codebuild.coworking_space_deploy_name
  coworking_space_codepipeline_role_arn=module.iam.coworking_space_codepipeline_role_arn
  github_connection_arn = module.codestar.github_connection_arn
}
