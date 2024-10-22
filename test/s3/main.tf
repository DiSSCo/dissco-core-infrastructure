provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}

resource "aws_s3_bucket" "data-export-bucket" {
  bucket = "dissco-data-export"
}

resource "aws_s3_bucket_public_access_block" "data-export-public-access" {
  bucket = aws_s3_bucket.data-export-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow-access-to-data-export" {
  bucket = aws_s3_bucket.data-export-bucket.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    principals {
      identifiers = ["*"]
      type = "*"
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.data-export-bucket.arn,
      "${aws_s3_bucket.data-export-bucket.arn}/*",
    ]
  }
  statement {
    principals {
      identifiers = ["//need agent arn"]
      type = "AWS"
    }
    actions = [
      "*"
    ]
    resources = [
      aws_s3_bucket.data-export-bucket.arn,
      "${aws_s3_bucket.data-export-bucket.arn}/*",
    ]
  }

}
