resource "aws_s3_bucket" "coworking_space_codepipeline" {
  bucket = "coworking-space-codepipeline"

  tags = {
    Name        = "coworking_space_codepipeline"
    Project     = "coworking_space"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "coworking_space_codepipeline_ownership_controls" {
  bucket = aws_s3_bucket.coworking_space_codepipeline.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "coworking_space_codepipeline_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.coworking_space_codepipeline_ownership_controls]

  bucket = aws_s3_bucket.coworking_space_codepipeline.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "coworking_space_codepipeline_versioning" {
  bucket = aws_s3_bucket.coworking_space_codepipeline.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "coworking_space_codepipeline_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.coworking_space_codepipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "coworking_space_codepipeline_lifecycle_configuration" {
  bucket = aws_s3_bucket.coworking_space_codepipeline.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
