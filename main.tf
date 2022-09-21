
# data block for fetching the latest ami 
data "aws_ami" "amazonLinux" {  // read from a data source (aws_ami) and export the result under "amazonLinux" - local name
  most_recent = true
  owners = ["amazon"]
  

  filter {
    name = "name"
    values = ["al2022-ami-2022.0.20220728.1-kernel-5.15-x86_64"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}
 
 // to output the ami id
output ami_id {
   value = data.aws_ami.amazonLinux.id

}

resource "aws_instance" "demo" { //resource <resource type> <resource local name>  = MAIN
 ami = data.aws_ami.amazonLinux.id
 instance_type = var.instance_type
 availability_zone = "us-east-1a" // var
 security_groups = [aws_security_group.T_Sec_Grp.name]
 # key_name = "demo_ec2"  //created using the console.. CAN BE DONE USING TF AS WELL

 tags = {
   "Name" = "my EC2"
 }
}
resource "aws_ebs_volume" "ebsvolume" {    // = for storage  
  availability_zone = "us-east-1a"
  size = 20
  #encrypted = false
  tags = {
    name = "prachiVol"
  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsvolume.id
  instance_id = aws_instance.demo.id
}


#securitygroup using Terraform

 resource "aws_security_group" "T_Sec_Grp" {
  name        = "security group using Terraform"
  description = "security group using Terraform"
  vpc_id      = "vpc-09e26a16cbd13b4cb" //SGs are vpc bounded

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "TF_Sec_Grp"
  }
 }

# key pair 
 resource "aws_key_pair" "T_key" {
  key_name   = "T_key"
  public_key = tls_private_key.rsa.public_key_openssh
}
#--> private key to be stored locally, to ssh on local machine
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "T-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "tfkey"
}

# creating S3 bucket
#S3 Bucket resource block 

# resource "aws_s3_bucket" "s3_Bucket" {
#   bucket = "kt-tf-my-s3-bucket"
#   //acl = "private"

#   tags = {
#     Name = "My S3 bucket"
#   }
# }
# Uploading single file to S3 Bucket

# resource "aws_s3_object" "s3_File"{
#     bucket = aws_s3_bucket.s3_Bucket.id
#     key = "provider.tf"
#     source = "D:\\VSCode\\Terraform\\provider.tf"

#     etag = filemd5("D:\\VSCode\\Terraform\\provider.tf")
# }

 # s3 backend configuration - terraform.tfstate file
terraform {
  backend "s3" {
    bucket = "prachi-s3-bucket"
    key    = "terraform.tfstate"  # -> directory inside s3 bucket
    region = "us-east-1"
 }
}

