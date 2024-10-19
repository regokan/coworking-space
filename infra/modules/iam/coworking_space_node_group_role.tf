resource "aws_iam_role" "coworking_space_node_group_role" {
  name = "coworking_space_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "coworking_space_node_group_role"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_node_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_cni_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_ec2_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
