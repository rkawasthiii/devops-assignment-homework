output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region of the bucket"
  value       = aws_s3_bucket.demo.region
}
