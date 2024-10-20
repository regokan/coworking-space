output "coworking_space_codepipeline_bucket" {
  value = aws_s3_bucket.coworking_space_codepipeline.bucket
}

output "coworking_space_codepipeline_bucket_arn" {
  value = aws_s3_bucket.coworking_space_codepipeline.arn
}
