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
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 22
        to_port = 22
        protocol = "tcp"
    }// Terraform removes the default rule
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "example_server" {
  ami           = "ami-04ba8620fc44e2264"                    
  instance_type = "t2.micro"
  security_groups = [ "${aws_security_group.ingress-all-test.id}" ]
  subnet_id = "${aws_subnet.subnet-uno.id}"
  tags = {
    Name = "MyServer"
  }
  user_data=<<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzhdCoWE/CiY3laW9R/I5UEhQs7krz8ur8OOg7su5MJ example@example" >> /home/ubuntu/.ssh/authorized_keys
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