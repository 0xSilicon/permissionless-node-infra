output "ec2_instance_info" {
  value = {
    name = aws_instance.this.tags.Name
    id = aws_instance.this.id
    private_ip = aws_instance.this.private_ip
    public_ip = aws_instance.this.public_ip
  }
  description = "ec2 instance info"
}