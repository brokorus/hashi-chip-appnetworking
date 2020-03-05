provider aws {
  region = "us-west-1"
  alias  = "us-west-1"
}

provider aws {
  region = "eu-central-1"
  alias  = "eu-central-1"
}

provider aws {
  region = "us-west-2"
  alias  = "us-west-2"
}

data "aws_availability_zones" "us-west-1" {
  provider = aws.us-west-1
  state    = "available"
}

data "aws_availability_zones" "us-west-2" {
  state    = "available"
  provider = aws.us-west-2
}

data "aws_availability_zones" "eu-central-1" {
  state    = "available"
  provider = aws.eu-central-1
}

module "west1_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.1.0.0/16"
  providers = {
    aws = aws.us-west-1
  }

  name            = "brokorus-west1app-vpc"
  azs             = data.aws_availability_zones.us-west-1.names
  private_subnets = [for zone in data.aws_availability_zones.us-west-1.names : "10.1.${index(data.aws_availability_zones.us-west-1.names, zone)}.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "west2_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.2.0.0/16"
  providers = {
    aws = aws.us-west-2
  }

  name            = "brokorus-west2app-vpc"
  azs             = data.aws_availability_zones.us-west-2.names
  private_subnets = [for zone in data.aws_availability_zones.us-west-2.names : "10.2.${index(data.aws_availability_zones.us-west-2.names, zone)}.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "eucentral1_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.3.0.0/16"
  providers = {
    aws = aws.eu-central-1
  }

  name            = "brokorus-eucentral1app-vpc"
  azs             = data.aws_availability_zones.eu-central-1.names
  private_subnets = [for zone in data.aws_availability_zones.eu-central-1.names : "10.3.${index(data.aws_availability_zones.eu-central-1.names, zone)}.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "west1_to_west2_peer" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west1_vpc.vpc_id
  peer_vpc_id         = module.west2_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-1
    aws.peer = aws.us-west-2
  }
  tags         = var.common_tags
  this_vpc_rts = module.west1_vpc.private_route_table_ids
  peer_vpc_rts = module.west2_vpc.private_route_table_ids
}

module "west1_to_eu1_peer" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west1_vpc.vpc_id
  peer_vpc_id         = module.eucentral1_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-1
    aws.peer = aws.eu-central-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.west1_vpc.private_route_table_ids
  peer_vpc_rts = module.eucentral1_vpc.private_route_table_ids
}

module "west2_to_eu1_peer" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west2_vpc.vpc_id
  peer_vpc_id         = module.eucentral1_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-2
    aws.peer = aws.eu-central-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.west2_vpc.private_route_table_ids
  peer_vpc_rts = module.eucentral1_vpc.private_route_table_ids
}

module "west1_admin_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.4.0.0/16"
  providers = {
    aws = aws.us-west-1
  }

  name            = "brokorus-uswest1admin-vpc"
  azs             = [data.aws_availability_zones.us-west-1.names[0], data.aws_availability_zones.us-west-1.names[1]]
  private_subnets = ["10.4.0.0/24", "10.4.1.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "west2_admin_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.5.0.0/16"
  providers = {
    aws = aws.us-west-2
  }

  name            = "brokorus-uswest2admin-vpc"
  azs             = [data.aws_availability_zones.us-west-2.names[0], data.aws_availability_zones.us-west-2.names[1]]
  private_subnets = ["10.5.0.0/24", "10.5.1.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "eucentral1_admin_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  cidr   = "10.6.0.0/16"
  providers = {
    aws = aws.eu-central-1
  }

  name            = "brokorus-eucentral1admin-vpc"
  azs             = [data.aws_availability_zones.eu-central-1.names[0], data.aws_availability_zones.eu-central-1.names[1]]
  private_subnets = ["10.6.0.0/24", "10.6.1.0/24"]

  public_subnet_tags = var.common_tags
  tags               = var.common_tags
  vpc_tags           = var.common_tags
}

module "west1_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west1_vpc.vpc_id
  peer_vpc_id         = module.west1_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-1
    aws.peer = aws.us-west-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.west1_vpc.private_route_table_ids
  peer_vpc_rts = module.west1_admin_vpc.private_route_table_ids
}

module "west2_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west2_vpc.vpc_id
  peer_vpc_id         = module.west2_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-2
    aws.peer = aws.us-west-2
  }
  tags         = var.common_tags
  this_vpc_rts = module.west2_vpc.private_route_table_ids
  peer_vpc_rts = module.west2_admin_vpc.private_route_table_ids
}

module "eucentral1_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.eucentral1_vpc.vpc_id
  peer_vpc_id         = module.eucentral1_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.eu-central-1
    aws.peer = aws.eu-central-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.eucentral1_vpc.private_route_table_ids
  peer_vpc_rts = module.eucentral1_admin_vpc.private_route_table_ids
}

module "west1_eucentral1_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west1_admin_vpc.vpc_id
  peer_vpc_id         = module.eucentral1_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-1
    aws.peer = aws.eu-central-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.west1_admin_vpc.private_route_table_ids
  peer_vpc_rts = module.eucentral1_admin_vpc.private_route_table_ids
}

module "west2_eucentral_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west2_admin_vpc.vpc_id
  peer_vpc_id         = module.eucentral1_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-2
    aws.peer = aws.eu-central-1
  }
  tags         = var.common_tags
  this_vpc_rts = module.west2_admin_vpc.private_route_table_ids
  peer_vpc_rts = module.eucentral1_admin_vpc.private_route_table_ids
}
#
module "west1_west2_admin_peering" {
  source              = "./modules/terraform-aws-vpc-peering/"
  this_vpc_id         = module.west1_admin_vpc.vpc_id
  peer_vpc_id         = module.west2_admin_vpc.vpc_id
  auto_accept_peering = true
  providers = {
    aws.this = aws.us-west-1
    aws.peer = aws.us-west-2
  }
  tags         = var.common_tags
  this_vpc_rts = module.west1_admin_vpc.private_route_table_ids
  peer_vpc_rts = module.west2_admin_vpc.private_route_table_ids
}

#module "west1_bastion" {
#  source                      = "terraform-aws-modules/ec2-instance/aws"
#  version                     = "~> 2.0"
#  provider                    = aws.us-west-1
#  associate_public_ip_address = true
#  ami                         = "ami-ebd02392"
#  instance_type               = "t2.micro"
#  key_name                    = "brokorus-key"
#  subnet_id                   = "10.4.0.0/24"
#
#  tags = {
#    Terraform   = "true"
#    Environment = "dev"
#  }
#}

#module "west2_bastion" {
#  source                      = "terraform-aws-modules/ec2-instance/aws"
#  version                     = "~> 2.0"
#  provider                    = aws.us-west-2
#  associate_public_ip_address = true
#  ami                         = "ami-ebd02392"
#  instance_type               = "t2.micro"
#  key_name                    = "brokorus-key"
#  subnet_id                   = "10.5.0.0/24"
#	name                        = "west2-central-bastion"
#
#  tags = {
#    Terraform   = "true"
#    Environment = "dev"
#  }
#}
#
#module "eucentral1_bastion" {
#  source                      = "terraform-aws-modules/ec2-instance/aws"
#  version                     = "~> 2.0"
#  provider                    = aws.eu-central-1
#  associate_public_ip_address = true
#  ami                         = "ami-ebd02392"
#  instance_type               = "t2.micro"
#  key_name                    = "brokorus-key"
#  subnet_id                   = "10.6.0.0/24"
#	name                        = "eu1-central-bastion"
#
#  tags = {
#    Terraform   = "true"
#    Environment = "dev"
#  }
#}
#
#resource "aws_security_group" "allow_ssh" {
#  name        = "allow_ssh"
#  description = "Allow TLS inbound traffic"
#  vpc_id      = "${aws_vpc.main.id}"
#  provider    = aws.us-west-1
#
#  ingress {
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = "0.0.0.0/0"
#  }
#
#  tags = var.common_tags
#}
