#output IAM
output "iam_role_arn" {
  value = aws_iam_role.app_role.arn
}
