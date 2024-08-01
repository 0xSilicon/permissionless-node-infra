variable "name" { type = string }

resource "aws_iam_role" "this" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
          Action = "sts:AssumeRole",
          Effect = "Allow",
          Principal = {
              Service = "ec2.amazonaws.com"
          }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  name = "${aws_iam_role.this.name}_profile"
  role = aws_iam_role.this.name
}

#TODO: consider move to system manager section?


output "ssm_role_info" {
  value = {
    role_name = aws_iam_role.this.name
    role_arn = aws_iam_role.this.arn
    instance_profile_name = aws_iam_instance_profile.this.name
  }
}