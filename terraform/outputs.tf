output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "s3_bucket_name" {
  value = aws_s3_bucket.main.id
}
output "source_bucket_name" {
  value = aws_s3_bucket.source_code.id
}
