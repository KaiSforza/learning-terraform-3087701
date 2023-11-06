module "qa" {
  source = "../modules/blog"

  environment = {
    name = "qa"
    prefix = "10.1"
  }

  asg_min_size = 1
  asg_max_size = 1
}