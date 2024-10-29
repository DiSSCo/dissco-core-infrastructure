resource "aws_s3_bucket" "col-indexes" {
  bucket = "col-indexes"
}

resource "aws_iam_user" "col-indexes-user" {
  name = "col-indexes-user"
}

data "aws_iam_policy_document" "col-indexes-ro" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    resources = ["${aws_s3_bucket.col-indexes.arn}/*"]
  }
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