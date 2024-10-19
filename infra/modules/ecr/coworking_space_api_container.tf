# ECR for Coworking Space API
resource "aws_ecr_repository" "coworking_space_api" {
  name                 = "coworking_space_api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "coworking_space_api"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}