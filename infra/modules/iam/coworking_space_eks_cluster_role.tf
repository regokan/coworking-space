resource "aws_iam_role" "coworking_space_eks_role" {
  name = "coworking_space_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "coworking_space_eks_role"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "coworking_space_eks_role_policy_attachment" {
  role       = aws_iam_role.coworking_space_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "coworking_space_eks_role_vpc_resource_controller_policy_attachment" {
  role       = aws_iam_role.coworking_space_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
