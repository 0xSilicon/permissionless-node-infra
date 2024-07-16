resource "aws_route_table" "public" {
  count = length(aws_subnet.public)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${aws_subnet.public[count.index].tags.Name}-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  route_table_id = aws_route_table.public[count.index].id
  subnet_id = aws_subnet.public[count.index].id
}

resource "aws_route" "public" {
  count = length(aws_subnet.public)
  route_table_id = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${aws_subnet.private[count.index].tags.Name}-route-table"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  route_table_id = aws_route_table.private[count.index].id
  subnet_id = aws_subnet.private[count.index].id
}

resource "aws_route" "private" {
  count = length(aws_subnet.private)
  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table" "db" {
  count = length(aws_subnet.db)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${aws_subnet.db[count.index].tags.Name}-route-table"
  }
}

resource "aws_route_table_association" "db" {
  count = length(aws_subnet.db)
  route_table_id = aws_route_table.db[count.index].id
  subnet_id = aws_subnet.db[count.index].id
}

resource "aws_route" "db" {
  count = length(aws_subnet.db)
  route_table_id = aws_route_table.db[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[count.index].id
}