variable "coworking_space_codepipeline_bucket" {
    description = "Coworking Space CodePipeline S3 bucket"
    type        = string
}

variable "coworking_space_build_name" {
    description = "Coworking Space CodeBuild project name"
    type        = string
}

variable "coworking_space_deploy_name" {
    description = "Coworking Space CodeBuild project name"
    type        = string
}

variable "coworking_space_codepipeline_role_arn" {
    description = "Coworking Space CodePipeline IAM role ARN"
    type        = string
}

variable "github_connection_arn" {
    description = "GitHub CodeStar Connection ARN"
    type        = string
}
