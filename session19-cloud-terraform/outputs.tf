output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "instance_public_ip" {
  description = "Public IP of the web instance — open http://<ip> to see the page"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}
