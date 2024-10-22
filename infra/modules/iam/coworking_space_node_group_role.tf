resource "aws_iam_role" "coworking_space_node_group_role" {
  name = "coworking_space_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
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

# Attach EKS worker node policy
resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_node_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach EKS CNI policy for networking
resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_cni_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach ECR read-only policy for pulling container images
resource "aws_iam_role_policy_attachment" "coworking_space_node_group_role_ec2_policy_attachment" {
  role       = aws_iam_role.coworking_space_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Inline policy for managing EBS volumes
resource "aws_iam_role_policy" "coworking_space_node_group_role_ebs_policy" {
  role = aws_iam_role.coworking_space_node_group_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        Resource = "*"
      }
    ]
  })
}
