resource "aws_s3_bucket" "tf_ops" {
  bucket = var.s3_bucket
}

resource "aws_s3_bucket_ownership_controls" "tf_ops" {
  bucket = aws_s3_bucket.tf_ops.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_ops" {
  depends_on = [  aws_s3_bucket_ownership_controls.tf_ops ]
  bucket = aws_s3_bucket.tf_ops.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}