variable "coworking_space_codebuild_role_arn" {
  description = "Coworking Space CodeBuild IAM role ARN"
  type        = string
}

variable "coworking_space_codebuild_deploy_role_arn" {
  description = "Coworking Space CodeBuild IAM role ARN"
  type        = string
}

variable "coworking_space_api_repository_url" {
  description = "Coworking Space API ECR repository URL"
  type        = string
}

variable "coworking_space_eks_cluster_name" {
  description = "Coworking Space EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}
