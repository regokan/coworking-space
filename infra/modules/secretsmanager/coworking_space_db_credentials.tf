resource "aws_secretsmanager_secret" "coworking_space_db_credentials" {
  name        = "coworking_space_db_credentials"
  description = "Credentials for the Coworking Space database"

  tags = {
    Name        = "coworking_space_db_credentials"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}
