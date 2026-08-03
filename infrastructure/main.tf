terraform {
  backend "s3" {
    bucket       = "techflow-terraform-state-leandro2026"
    key          = "techflow/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name = "${var.project_name}-VPC"
  vpc_cidr     = "10.0.0.0/16"

  public_subnet_cidr_1 = "10.0.1.0/24"
  public_subnet_cidr_2 = "10.0.2.0/24"

  private_subnet_cidr_1 = "10.0.10.0/24"
  private_subnet_cidr_2 = "10.0.11.0/24"

  availability_zone_public_1 = "us-east-2a"
  availability_zone_public_2 = "us-east-2b"

  availability_zone_private_1 = "us-east-2a"
  availability_zone_private_2 = "us-east-2b"

}

module "s3" {
  source = "./modules/s3/"

  project_name           = "${var.project_name}-S3"
  s3_bucket_name_log     = var.bucket_name_log
  s3_bucket_name_backups = var.bucket_name_backups

}

module "iam" {
  source = "./modules/iam/"

  project_name       = "${var.project_name}-IAM"
  log_bucket_arn     = module.s3.log_bucket_arn
  backups_bucket_arn = module.s3.backups_bucket_arn

}

module "ec2" {
  source = "./modules/ec2/"

  project_name     = "${var.project_name}-ec2-instance"
  ami              = data.aws_ami.amazon_linux_2.id
  instance_type    = var.instance_type
  subnet_id        = module.vpc.public_subnet_ids[0]
  vpc_id           = module.vpc.vpc_id
  my_ip            = "${trimspace(data.http.my_ip.response_body)}/32"
  instance_profile = module.iam.instance_profile
}

module "rds" {
  source = "./modules/rds/"

  project_name       = "${var.project_name}-rds"
  vpc_id             = module.vpc.vpc_id
  sg_ec2_id          = module.ec2.sg_ec2_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_password        = var.db_password

}

module "alb" {
  source = "./modules/alb/"

  project_name      = "${var.project_name}-alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ec2_instance_id   = module.ec2.instance_id
}

