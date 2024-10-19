terraform {
  backend "s3" {
    bucket = "coworking-space-api-tf-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}
