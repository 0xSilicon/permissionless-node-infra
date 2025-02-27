variable "name" { type = string }

resource "aws_iam_role" "this" {
    name = var.name

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Sid       = "AllowIAMauthentication",
            Effect    = "Allow",
            Principal = {
            Service = "rds.amazonaws.com"
            },
            Action    = "sts:AssumeRole"
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "this" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    role      = aws_iam_role.this.name
}

output "rds_role_info" {
  value = {
    name = aws_iam_role.this.name
    arn = aws_iam_role.this.arn
  }
}