terraform {
  required_version = ">= 1.0.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }

  backend "local" {
    path = "local_tf_state/terraform-main.tfstate"
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu-eks/k8s_${local.cluster_version}/images/*" # Ubuntu Server for EKS, SSD Volume Type

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["099720109477"] # Canonical
}

data "aws_subnet" "one" {
  id = module.aws_vpc.private_subnets[0]
}
data "aws_subnet" "two" {
  id = module.aws_vpc.private_subnets[1]
}
data "aws_subnet" "three" {
  id = module.aws_vpc.private_subnets[2]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks-blueprints.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-blueprints.eks_cluster_id
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

locals {
  tenant      = "aws001"  # AWS account name or unique id for tenant
  environment = "preprod" # Environment area eg., preprod or prod
  zone        = "dev"     # Environment with in one sub_tenant or business unit

  cluster_version = "1.21"

  vpc_cidr     = "10.0.0.0/16"
  vpc_name     = join("-", [local.tenant, local.environment, local.zone, "vpc"])
  cluster_name = join("-", [local.tenant, local.environment, local.zone, "eks"])
  etcd_name    = join("-", [local.tenant, local.environment, local.zone, "etcd"])

  terraform_version = "Terraform v1.1.7"

  iam_policy_name = join("-", [local.tenant, local.environment, local.zone, "ondat", "data"])
  iam_policies    = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name}"]

  userdata_one   = join("\n", ["#!/bin/bash", module.persist-ebs.userdata_snippets_by_az[data.aws_subnet.one.availability_zone]])
  userdata_two   = join("\n", ["#!/bin/bash", module.persist-ebs.userdata_snippets_by_az[data.aws_subnet.two.availability_zone]])
  userdata_three = join("\n", ["#!/bin/bash", module.persist-ebs.userdata_snippets_by_az[data.aws_subnet.three.availability_zone]])
}

resource "aws_iam_policy" "data" {
  name   = local.iam_policy_name
  policy = module.persist-ebs.iam_role_policy_document
}

resource "aws_security_group" "etcd_access" {
  name        = join("-", [local.iam_policy_name, "etcd-access"])
  description = "Allow access to etcd and between Ondat clients"
  vpc_id      = module.aws_vpc.vpc_id
}

resource "aws_security_group_rule" "ondat_access_tcp" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_access_udp" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_api_tcp" {
  type              = "ingress"
  from_port         = 5703
  to_port           = 5705
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_rwx_tcp" {
  type              = "ingress"
  from_port         = 25695
  to_port           = 25960
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_grpc_tcp" {
  type              = "ingress"
  from_port         = 5701
  to_port           = 5701
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_gossip_tcp" {
  type              = "ingress"
  from_port         = 5710
  to_port           = 5711
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "ondat_gossip_udp" {
  type              = "ingress"
  from_port         = 5710
  to_port           = 5711
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.etcd_access.id
}

resource "aws_security_group_rule" "etcd_access" {
  type      = "egress"
  from_port = 2379
  to_port   = 2379
  protocol  = "tcp"
  # Unfortunately, NLBs don't like SG-based rules
  cidr_blocks       = module.aws_vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.etcd_access.id
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.2.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = data.aws_availability_zones.available.names

  public_subnets       = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets      = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

#---------------------------------------------------------------
# Example to consume etcd3-terraform module
#---------------------------------------------------------------
module "etcd" {
  source     = "github.com/ondat/etcd3-terraform"
  vpc_id     = module.aws_vpc.vpc_id
  subnet_ids = module.aws_vpc.private_subnets

  ssd_size      = 32
  instance_type = "t3.large"

  client_cidrs = module.aws_vpc.private_subnets_cidr_blocks # etcd access for private nodes
  dns          = "${local.etcd_name}.int"
  environment  = "a"
}

#---------------------------------------------------------------
# Example to consume eks-blueprints module
#---------------------------------------------------------------
module "eks-blueprints" {
  source            = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=faf2f9"
  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone
  terraform_version = local.terraform_version

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets

  # SG config for etcd access
  worker_additional_security_group_ids = [aws_security_group.etcd_access.id]

  # EKS CONTROL PLANE VARIABLES
  cluster_version = local.cluster_version

  managed_node_groups = {
    ondat_1 = {
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_one
      additional_iam_policies = local.iam_policies
      node_group_name         = "managed-ondat-ondemand-1"
      additional_tags         = { Group = join("-", [local.tenant, local.environment, local.zone, "ondat"]) }
      subnet_ids              = [data.aws_subnet.one.id]
      ami_type                = "CUSTOM"
      instance_types          = ["t3.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node"       = "1"
        "storageos-node-group" = "ondat-1"
      }
    }
    ondat_2 = {
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_two
      additional_iam_policies = local.iam_policies
      node_group_name         = "managed-ondat-ondemand-2"
      additional_tags         = { Group = join("-", [local.tenant, local.environment, local.zone, "ondat"]) }
      subnet_ids              = [data.aws_subnet.two.id]
      ami_type                = "CUSTOM"
      instance_types          = ["t3.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node"       = "1"
        "storageos-node-group" = "ondat-2"
      }
    }
    ondat_3 = {
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_three
      additional_iam_policies = local.iam_policies
      node_group_name         = "managed-ondat-ondemand-3"
      additional_tags         = { Group = join("-", [local.tenant, local.environment, local.zone, "ondat"]) }
      subnet_ids              = [data.aws_subnet.three.id]
      ami_type                = "CUSTOM"
      instance_types          = ["t3.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node"       = "1"
        "storageos-node-group" = "ondat-3"
      }
    }
  }
}

module "persist-ebs" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs"

  group = join("-", [local.tenant, local.environment, local.zone, "ondat"])
  attached_ebs = {
    "storageos-config-ondat-0" = {
      size                    = 10
      availability_zone       = data.aws_subnet.one.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-0" = {
      size                    = 100
      availability_zone       = data.aws_subnet.one.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdg"
      block_device_os         = "/dev/nvme3n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
    "storageos-config-ondat-1" = {
      size                    = 10
      availability_zone       = data.aws_subnet.two.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-1" = {
      size                    = 100
      availability_zone       = data.aws_subnet.two.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdg"
      block_device_os         = "/dev/nvme3n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
    "storageos-config-ondat-2" = {
      size                    = 10
      availability_zone       = data.aws_subnet.three.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-2" = {
      size                    = 100
      availability_zone       = data.aws_subnet.three.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdg"
      block_device_os         = "/dev/nvme3n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}

module "eks-blueprints-kubernetes-addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=faf2f9"

  eks_cluster_id = module.eks-blueprints.eks_cluster_id

  # EKS Addons
  enable_ondat = true # default is false

  ondat_etcd_endpoints = ["https://${module.etcd.lb_address}:2379"]
  ondat_etcd_ca        = module.etcd.ca_cert
  ondat_etcd_cert      = module.etcd.client_cert
  ondat_etcd_key       = module.etcd.client_key
  ondat_admin_username = "storageos"
  ondat_admin_password = "storageos"

  depends_on = [module.eks-blueprints.managed_node_groups]
}
