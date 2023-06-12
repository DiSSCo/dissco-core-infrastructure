resource "aws_s3_bucket" "bucket" {
  bucket = "dissco-terraform-state-backend"

  object_lock_enabled = true

  tags = {
    name = "S3 Remote Terraform State Store",
    environment = "generic"
  }
}

resource "aws_s3_bucket_versioning" "s3-versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3-encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
