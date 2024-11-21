resource "aws_subnet" "public" {
  vpc_id = aws_vpc.this.id

  count = length(var.availability_zones)
  cidr_block = cidrsubnet(
    aws_vpc.this.cidr_block,
    var.subnets.newbits,
    var.subnets.public_netnum + count.index
  )

  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-${format("%02d", count.index + 1)}-${var.vpc.vpc_name}}"
  }
  depends_on = [ aws_vpc.this ]
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(
    aws_vpc.this.cidr_block,
    var.subnets.newbits,
    var.subnets.private_netnum + count.index
  )

  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-${format("%02d", count.index + 1)}-${var.vpc.vpc_name}}"
  }
}

resource "aws_subnet" "db" {
  count = var.skipRDS == true ? 0 : length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(
    aws_vpc.this.cidr_block,
    var.subnets.newbits,
    var.subnets.db_netnum + count.index
  )

  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "db-${format("%02d", count.index + 1)}-${var.vpc.vpc_name}}"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${replace(aws_vpc.this.tags.Name,"_","-")}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}