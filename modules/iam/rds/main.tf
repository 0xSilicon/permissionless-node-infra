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

resource "aws_iam_policy_attachment" "this" {
    name       = "${aws_iam_role.this.name}_rds_policy_attachment"
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    roles      = [aws_iam_role.this.name]
}

output "rds_role_info" {
  value = {
    name = aws_iam_role.this.name
    arn = aws_iam_role.this.arn
  }
}