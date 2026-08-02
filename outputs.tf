output "cloudfront_url" {
  description = "Die URL der Webseite über CloudFront (HTTPS)"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID" 
  value = aws_cloudfront_distribution.website.id
}

output "s3_bucket_name" {
  description = "Name des erstellten S3-Buckets"
  value       = aws_s3_bucket.website.bucket
}

output "s3_bucket_arn" {
  description = "ARN des S3-Buckets"
  value = aws_s3_bucket.website.arn
}