variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "coworking_space_node_group_role_arn" {
  description = "Coworking Space Node group IAM role ARN"
  type        = string
}

variable "coworking_space_eks_cluster_role_arn" {
  description = "Coworking Space EKS cluster IAM role ARN"
  type        = string
}

variable "coworking_space_eks_role_policy_attachment" {
  description = "Coworking Space EKS role policy attachment"
  type        = string
}

variable "coworking_space_eks_role_vpc_resource_controller_policy_attachment" {
  description = "Coworking Space EKS role VPC resource controller policy attachment"
  type        = string
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}
