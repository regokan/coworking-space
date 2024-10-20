resource "aws_codestarconnections_connection" "github_connection" {
  name     = "github-connection"
  provider_type = "GitHub"

  tags = {
    Name        = "github_connection"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
