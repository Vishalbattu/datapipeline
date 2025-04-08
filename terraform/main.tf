# S3 Bucket for Source Data (Supplier Uploads)
resource "aws_s3_bucket" "source_data" {
    bucket = var.source_bucket_name
    

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
        }
    }
}

# Bucket Policy to Allow Third-Party Vendors to Upload Files
resource "aws_s3_bucket_policy" "source_data_policy" {
    bucket = aws_s3_bucket.source_data.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Principal = {
            "AWS": var.vendor_account_id  # update vendor id in tfvars
            },
            Action = [
            "s3:PutObject",
            "s3:ListBucket"
            ],
            Resource = [
            "${aws_s3_bucket.source_data.arn}/*",
            "${aws_s3_bucket.source_data.arn}"
            ]
        }
        ]
    })
}

# S3 Bucket for Private Record Files
resource "aws_s3_bucket" "private_records" {
    bucket = var.private_records_bucket_name
    acl    = "private"

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
        }
    }
}

# S3 Bucket for Private Token Files
resource "aws_s3_bucket" "private_tokens" {
    bucket = var.private_tokens_bucket_name
    acl    = "private"

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
        }
    }
}

# S3 Bucket for Access Logs (Target Bucket for Logging)
resource "aws_s3_bucket" "target_bucket" {
    bucket = "diaceutics-log-bucket"  
    acl    = "log-delivery-write"     # Grant permission for S3 to write logs to this bucket

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

# Enable Access Logging on the Source Data Bucket
resource "aws_s3_bucket_logging" "source_data_logging" {
    bucket        = aws_s3_bucket.source_data.id      
    target_bucket = aws_s3_bucket.target_bucket.id    
    target_prefix = "logs/"                           
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
    name = "lambda_exec_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
            Service = "lambda.amazonaws.com"
        }
        }]
    })
}

# IAM Policy for Lambda to Access S3 Buckets
resource "aws_iam_role_policy" "lambda_s3_policy" {
    role = aws_iam_role.lambda_exec_role.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
            ],
            Effect = "Allow",
            Resource = [
            "${aws_s3_bucket.source_data.arn}/*",
            "${aws_s3_bucket.private_records.arn}/*",
            "${aws_s3_bucket.private_tokens.arn}/*"
            ]
        }
        ]
    })
}

# Lambda Function for File Processing
resource "aws_lambda_function" "file_processor" {
    function_name = "file-processor"
    role          = aws_iam_role.lambda_exec_role.arn
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.9"
    filename      = "${path.module}/../lambda/lambda.zip"
    source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")

    environment {
        variables = {
        RECORD_BUCKET = aws_s3_bucket.private_records.bucket
        TOKEN_BUCKET  = aws_s3_bucket.private_tokens.bucket
        }
    }
}

# Permission for S3 to Invoke Lambda Function
resource "aws_lambda_permission" "allow_s3_invocation" {
    statement_id  = "AllowS3Invoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.file_processor.function_name
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.source_data.arn
}

# S3 Bucket Notification to Trigger Lambda on File Upload
resource "aws_s3_bucket_notification" "source_data_notification" {
    bucket = aws_s3_bucket.source_data.id

    lambda_function {
        lambda_function_arn = aws_lambda_function.file_processor.arn
        events              = ["s3:ObjectCreated:*"]
    }

    depends_on = [aws_lambda_permission.allow_s3_invocation]
}
