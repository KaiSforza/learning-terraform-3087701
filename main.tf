data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["${var.environment.prefix}.1.0/24", "${var.environment.prefix}.2.0/24", "${var.environment.prefix}.3.0/24"]
  public_subnets  = ["${var.environment.prefix}.101.0/24", "${var.environment.prefix}.102.0/24", "${var.environment.prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

# resource "aws_instance" "blog" {
#   ami           = data.aws_ami.app_ami.id
#   instance_type = var.instance_type
# 
#   subnet_id = module.blog_vpc.public_subnets[0]
# 
#   vpc_security_group_ids = [module.blog_sg.security_group_id]
# 
#   tags = {
#     Name = "HelloWorld"
#   }
# }

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.2.0"
  name = "${var.environment.name}-blog"

  min_size = var.asg_min_size
  max_size = var.asg_max_size
  
  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns = [module.blog_alb.target_groups.blog.arn]
  security_groups = [module.blog_sg.security_group_id]

  image_id = data.aws_ami.app_ami.id
  instance_type = var.instance_type
}

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.environment.name}-blog-alb"

  load_balancer_type = "application"

  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  target_groups = {
    blog = {
      name_prefix      = "${var.environment.name}-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      create_attachment = false
    }
  }

  listeners = {
    blog-http = {
      port     = 80
      protocol = "HTTP"
      # target_group_key = "blog"
      forward = {
        target_group_key = "blog"
      }
    }
  }


  tags = {
    Environment = var.environment.name
    Project     = "blog"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name = "${var.environment.name}-blog"

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

