resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name = "eip-${format("%02d", count.index+1)}-nat-gw"
  }
}

resource "aws_nat_gateway" "this" {
  count = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gw-${format("%02d", count.index+1)}-${aws_vpc.this.tags.Name}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-${aws_vpc.this.tags.Name}"
  }
}
