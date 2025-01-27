resource "aws_vpc" "test-env" {
  cidr_block = "10.11.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}
resource "aws_subnet" "subnet-uno" {
  cidr_block = "${cidrsubnet(aws_vpc.test-env.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.test-env.id}"
  availability_zone = "eu-west-2a"
}

resource "aws_security_group" "ingress-all-test" {
    name = "allow-all-sg"
    vpc_id = "${aws_vpc.test-env.id}"
    # ingress {
    #     cidr_blocks = ["0.0.0.0/0"]
    #     from_port = 22
    #     to_port = 22
    #     protocol = "tcp"
    # }// Terraform removes the default rule
    # egress {
    #     from_port = 0
    #     to_port = 0
    #     protocol = "-1"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }
}
# resource "aws_vpc_security_group_egress_rule" "egress-all" {
#   cidr_ipv4   = "10.0.0.0/8"
#   from_port   = 0
#   ip_protocol = "tcp"
#   to_port     = 0
# }
resource "aws_security_group_rule" "allow_all_egress" {
  security_group_id = aws_security_group.ingress-all-test.id
  type              = "egress"    # 🔄 Outbound traffic
  from_port         = 0           # 🔑 Any Port
  to_port           = 65535       # 🔑 Any Port
  protocol          = "-1"        # 🌐 Any Protocol
  cidr_blocks       = ["0.0.0.0/0"]  # 🌍 Any IP
}

# resource "aws_vpc_security_group_ingress_rule" "ingress-ssh" {
#   security_group_id = aws_security_group.ingress-all-test.id
#   cidr_ipv4   = "10.0.0.0/8"
#   from_port   = 22
#   ip_protocol = "tcp"
#   to_port     = 22
# }
# resource "aws_vpc_security_group_ingress_rule" "ingress-http" {
#   security_group_id = aws_security_group.ingress-all-test.id
#   cidr_ipv4   = "10.0.0.0/8"
#   from_port   = 80
#   ip_protocol = "tcp"
#   to_port     = 80
# }
resource "aws_security_group_rule" "allow_http" {
  security_group_id = aws_security_group.ingress-all-test.id
  type              = "ingress"   # 🔥 Inbound traffic
  from_port         = 80          # 🔑 Port 80 for HTTP
  to_port           = 80          # 🔑 Allow to Port 80
  protocol          = "tcp"       # 📡 TCP Protocol
  cidr_blocks       = ["0.0.0.0/0"]  # 🌍 Any IP
}
resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = aws_security_group.ingress-all-test.id
  type              = "ingress"   # 🔥 Inbound traffic
  from_port         = 22          # 🔑 Port 80 for HTTP
  to_port           = 22          # 🔑 Allow to Port 80
  protocol          = "tcp"       # 📡 TCP Protocol
  cidr_blocks       = ["0.0.0.0/0"]  # 🌍 Any IP
}


resource "aws_instance" "example_server" {
  ami           = "ami-04ba8620fc44e2264"                    
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.ingress-all-test.id}" ]
  subnet_id = "${aws_subnet.subnet-uno.id}"
  tags = {
    Name = "MyServer"
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

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.example_server.id}"
  vpc      = true
}
resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.test-env.id}"
  
}
//subnets.tf
resource "aws_route_table" "route-table-test-env" {
    vpc_id = "${aws_vpc.test-env.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.test-env-gw.id}"
    }

}
resource "aws_route_table_association" "subnet-association" {
    subnet_id      = "${aws_subnet.subnet-uno.id}"
    route_table_id = "${aws_route_table.route-table-test-env.id}"
}

output "instance_ip_addr" {
  value = aws_instance.example_server.public_ip
}
output "eip_addr" {
  value = aws_eip.ip-test-env.public_ip
}
