resource "aws_vpc" "network-one" {
  cidr_block = "10.11.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}
resource "aws_subnet" "subnet-one" {
  cidr_block = "${cidrsubnet(aws_vpc.network-one.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.network-one.id}"
  availability_zone = "eu-west-2a"
}

resource "aws_internet_gateway" "network-one-gw" {
  vpc_id = "${aws_vpc.network-one.id}"
}
resource "aws_route_table" "route-table-network-one" {
    vpc_id = "${aws_vpc.network-one.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.network-one-gw.id}"
    }
}

resource "aws_security_group" "sec-group-one" {
    name = "allow-all-sg"
    vpc_id = "${aws_vpc.network-one.id}"
}

resource "aws_security_group_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sec-group-one.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http" {
  security_group_id = aws_security_group.sec-group-one.id
  type              = "ingress"
  from_port         = 80 
  to_port           = 80  
  protocol          = "tcp" 
  cidr_blocks       = ["0.0.0.0/0"] 
}
resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = aws_security_group.sec-group-one.id
  type              = "ingress"   
  from_port         = 22 
  to_port           = 22  
  protocol          = "tcp" 
  cidr_blocks       = ["0.0.0.0/0"] 
}


resource "aws_instance" "main-host" {
  ami           = "ami-04ba8620fc44e2264"                    
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.sec-group-one.id}" ]
  subnet_id = "${aws_subnet.subnet-one.id}"
  tags = {
    Name = "MainHost"
  }
  user_data=<<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzhdCoWE/CiY3laW9R/I5UEhQs7krz8ur8OOg7su5MJ example@example" >> /home/ec2-user/.ssh/authorized_keys
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user
docker run --rm -d -p 80:80 traefik/whoami
EOF
}

resource "aws_eip" "ip-network-one" {
  instance = "${aws_instance.main-host.id}"
  domain   = "vpc"
}

resource "aws_route_table_association" "subnet-association" {
    subnet_id      = "${aws_subnet.subnet-one.id}"
    route_table_id = "${aws_route_table.route-table-network-one.id}"
}

output "instance_ip_addr" {
  value = aws_instance.main-host.public_ip
}
output "eip_addr" {
  value = aws_eip.ip-network-one.public_ip
}
