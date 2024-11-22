provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Production"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}

# S3 Bucket for Data Exporter
resource "aws_iam_user" "export-bucket-agent" {
  name = "export-bucket-agent"
}

resource "aws_s3_bucket" "data-export-bucket" {
  bucket = "dissco-data-export-production"
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
      identifiers = [aws_iam_user.export-bucket-agent.arn]
      type = "AWS"
    }
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    resources = [
      aws_s3_bucket.data-export-bucket.arn,
      "${aws_s3_bucket.data-export-bucket.arn}/*",
    ]
  }
}


# S3 Buckets for COL Indexes

resource "aws_s3_bucket" "col-indexes" {
  bucket = "col-indexes"
}

resource "aws_iam_user" "col-indexes-user" {
  name = "col-indexes-user"
}

resource "aws_iam_user_policy" "col-indexes-user-policy" {
  name   = "col-indexes-user-policy"
  user   = aws_iam_user.col-indexes-user.name
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl"
        ],
        "Effect"   = "Allow",
        "Resource" = ["${aws_s3_bucket.col-indexes.arn}/*"]
      },
      {
        "Action" = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Effect"   = "Allow",
        "Resource" = [aws_s3_bucket.col-indexes.arn]
      }
    ]
  })
}
