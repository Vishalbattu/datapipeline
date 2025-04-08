output "source_data_bucket" {
  description = "Source data bucket"
  value       = aws_s3_bucket.source_data.bucket
}

output "private_records_bucket" {
  description = "Private records bucket"
  value       = aws_s3_bucket.private_records.bucket
}

output "private_tokens_bucket" {
  description = "Private tokens bucket"
  value       = aws_s3_bucket.private_tokens.bucket
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.file_processor.arn
}
