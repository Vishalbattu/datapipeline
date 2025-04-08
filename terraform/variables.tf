variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "source_bucket_name" {
  description = "The name of the S3 bucket for source data"
  type        = string
  default     = "diaceutics-source-bucket"
}

variable "private_records_bucket_name" {
  description = "The name of the S3 bucket for private records"
  type        = string
  default     = "diaceutics-private-records-bucket"
}

variable "private_tokens_bucket_name" {
  description = "The name of the S3 bucket for private tokens"
  type        = string
  default     = "diaceutics-private-tokens-bucket"
}

variable "vendor_account_id" {
  description = "The AWS account ID of the third-party vendor"
  type        = string
}
