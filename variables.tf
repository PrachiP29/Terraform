
/*variable "ami" {
    description = "Linux ami id"
    type = string
    default ="ami-0a0cf2b8bc4634fe1"
}*/

variable "instance_type" {
    description = "Instance type for ec2"
    type = string
    default = "t2.micro"
}