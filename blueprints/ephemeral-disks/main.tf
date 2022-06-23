provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks_blueprints.eks_cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_blueprints.eks_cluster_id]
    }
  }
}

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
  id = module.vpc.private_subnets[0]
}
data "aws_subnet" "two" {
  id = module.vpc.private_subnets[1]
}
data "aws_subnet" "three" {
  id = module.vpc.private_subnets[2]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

locals {
  name            = basename(path.cwd)
  cluster_version = "1.22"
  region          = var.aws_region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/ondat/terraform-eksblueprints-ondat-addon"
  }

  iam_policy_name_one   = join("-", [local.name, "ondat", "data", "1"])
  iam_policy_name_two   = join("-", [local.name, "ondat", "data", "2"])
  iam_policy_name_three = join("-", [local.name, "ondat", "data", "3"])
  iam_policy_name_four  = join("-", [local.name, "ondat", "data", "4"])
  iam_policy_name_five  = join("-", [local.name, "ondat", "data", "5"])
  iam_policies_one      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name_one}"]
  iam_policies_two      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name_two}"]
  iam_policies_three    = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name_three}"]
  iam_policies_four     = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name_four}"]
  iam_policies_five     = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.iam_policy_name_five}"]

  userdata_one   = join("\n", ["#!/bin/bash", module.attached_ebs_one.userdata_snippets_by_az[data.aws_subnet.one.availability_zone]])
  userdata_two   = join("\n", ["#!/bin/bash", module.attached_ebs_two.userdata_snippets_by_az[data.aws_subnet.two.availability_zone]])
  userdata_three = join("\n", ["#!/bin/bash", module.attached_ebs_three.userdata_snippets_by_az[data.aws_subnet.three.availability_zone]])
  userdata_four  = join("\n", ["#!/bin/bash", module.attached_ebs_four.userdata_snippets_by_az[data.aws_subnet.two.availability_zone]])
  userdata_five  = join("\n", ["#!/bin/bash", module.attached_ebs_five.userdata_snippets_by_az[data.aws_subnet.three.availability_zone]])
}

resource "aws_iam_policy" "data1" {
  name   = local.iam_policy_name_one
  policy = module.attached_ebs_one.iam_role_policy_document
}

resource "aws_iam_policy" "data2" {
  name   = local.iam_policy_name_two
  policy = module.attached_ebs_two.iam_role_policy_document
}

resource "aws_iam_policy" "data3" {
  name   = local.iam_policy_name_three
  policy = module.attached_ebs_three.iam_role_policy_document
}

resource "aws_iam_policy" "data4" {
  name   = local.iam_policy_name_four
  policy = module.attached_ebs_four.iam_role_policy_document
}

resource "aws_iam_policy" "data5" {
  name   = local.iam_policy_name_five
  policy = module.attached_ebs_five.iam_role_policy_document
}

resource "aws_security_group" "ondat_access" {
  name        = join("-", [local.name, "data", "ondat_access"])
  description = "Allow access between Ondat nodes"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ondat_access_tcp" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_access_udp" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_etcd_tcp" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_etcd_udp" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_api_tcp" {
  type              = "ingress"
  from_port         = 5703
  to_port           = 5705
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_rwx_tcp" {
  type              = "ingress"
  from_port         = 25695
  to_port           = 25960
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_grpc_tcp" {
  type              = "ingress"
  from_port         = 5701
  to_port           = 5701
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_gossip_tcp" {
  type              = "ingress"
  from_port         = 5710
  to_port           = 5711
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}

resource "aws_security_group_rule" "ondat_gossip_udp" {
  type              = "ingress"
  from_port         = 5710
  to_port           = 5711
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.ondat_access.id
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = local.tags
}

#---------------------------------------------------------------
# Example to consume eks_blueprints module
#---------------------------------------------------------------
module "eks_blueprints" {
  source          = "github.com/aws-ia/terraform-aws-eks-blueprints"
  cluster_name    = local.name
  cluster_version = local.cluster_version

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  # SG config for cross-node access
  worker_additional_security_group_ids = [aws_security_group.ondat_access.id]

  managed_node_groups = {
    ondat_1 = {
      block_device_mappings   = []
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_one
      additional_iam_policies = local.iam_policies_one
      format_mount_nvme_disk  = false
      node_group_name         = "managed-ondat-ondemand-1"
      additional_tags         = { Group = join("-", [local.name, "ondat", "1"]) }
      subnet_ids              = [data.aws_subnet.one.id]
      ami_type                = "CUSTOM"
      instance_types          = ["i3en.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node" = "1"
        "storageos-etcd" = "1"
      }
    }
    ondat_2 = {
      block_device_mappings   = []
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_two
      additional_iam_policies = local.iam_policies_two
      format_mount_nvme_disk  = false
      node_group_name         = "managed-ondat-ondemand-2"
      additional_tags         = { Group = join("-", [local.name, "ondat", "2"]) }
      subnet_ids              = [data.aws_subnet.two.id]
      ami_type                = "CUSTOM"
      instance_types          = ["i3en.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node" = "1"
        "storageos-etcd" = "1"
      }
    }
    ondat_3 = {
      block_device_mappings   = []
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_three
      additional_iam_policies = local.iam_policies_three
      format_mount_nvme_disk  = false
      node_group_name         = "managed-ondat-ondemand-3"
      additional_tags         = { Group = join("-", [local.name, "ondat", "3"]) }
      subnet_ids              = [data.aws_subnet.three.id]
      ami_type                = "CUSTOM"
      instance_types          = ["i3en.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node" = "1"
        "storageos-etcd" = "1"
      }
    }
    ondat_4 = {
      block_device_mappings   = []
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_four
      additional_iam_policies = local.iam_policies_four
      format_mount_nvme_disk  = false
      node_group_name         = "managed-ondat-ondemand-4"
      additional_tags         = { Group = join("-", [local.name, "ondat", "4"]) }
      subnet_ids              = [data.aws_subnet.two.id]
      ami_type                = "CUSTOM"
      instance_types          = ["i3en.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node" = "1"
        "storageos-etcd" = "1"
      }
    }
    ondat_5 = {
      block_device_mappings   = []
      create_launch_template  = true
      custom_ami_id           = data.aws_ami.ubuntu.id
      pre_userdata            = local.userdata_five
      additional_iam_policies = local.iam_policies_five
      format_mount_nvme_disk  = false
      node_group_name         = "managed-ondat-ondemand-5"
      additional_tags         = { Group = join("-", [local.name, "ondat", "5"]) }
      subnet_ids              = [data.aws_subnet.three.id]
      ami_type                = "CUSTOM"
      instance_types          = ["i3en.large"]
      desired_size            = 1
      max_size                = 1
      min_size                = 1
      max_unavailable         = 1
      k8s_labels = {
        "storageos-node" = "1"
        "storageos-etcd" = "1"
      }
    }
  }
}

#---------------------------------------------------------------
# Example to consume attached_ebs module for persistent data
#---------------------------------------------------------------
module "attached_ebs_one" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs?ref=v0.1.2"

  group = join("-", [local.name, "ondat", "1"])
  attached_ebs = {
    "storageos-config-ondat-1" = {
      size                    = 10
      availability_zone       = data.aws_subnet.one.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-1" = {
      availability_zone       = data.aws_subnet.one.availability_zone
      ephemeral               = true
      block_device_os         = "/dev/nvme1n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}
module "attached_ebs_two" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs?ref=v0.1.2"

  group = join("-", [local.name, "ondat", "2"])
  attached_ebs = {
    "storageos-config-ondat-2" = {
      size                    = 10
      availability_zone       = data.aws_subnet.two.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-2" = {
      availability_zone       = data.aws_subnet.two.availability_zone
      ephemeral               = true
      block_device_os         = "/dev/nvme1n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}
module "attached_ebs_three" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs?ref=v0.1.2"

  group = join("-", [local.name, "ondat", "3"])
  attached_ebs = {
    "storageos-config-ondat-3" = {
      size                    = 10
      availability_zone       = data.aws_subnet.three.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-3" = {
      availability_zone       = data.aws_subnet.three.availability_zone
      ephemeral               = true
      block_device_os         = "/dev/nvme1n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}
module "attached_ebs_four" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs?ref=v0.1.2"

  group = join("-", [local.name, "ondat", "4"])
  attached_ebs = {
    "storageos-config-ondat-4" = {
      size                    = 10
      availability_zone       = data.aws_subnet.two.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-4" = {
      availability_zone       = data.aws_subnet.two.availability_zone
      ephemeral               = true
      block_device_os         = "/dev/nvme1n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}
module "attached_ebs_five" {
  source = "github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs?ref=v0.1.2"

  group = join("-", [local.name, "ondat", "5"])
  attached_ebs = {
    "storageos-config-ondat-5" = {
      size                    = 10
      availability_zone       = data.aws_subnet.three.availability_zone
      encrypted               = true
      volume_type             = "gp3"
      block_device_aws        = "/dev/xvdf"
      block_device_os         = "/dev/nvme2n1"
      block_device_mount_path = "/var/lib/storageos"
    }
    "storageos-data-ondat-5" = {
      availability_zone       = data.aws_subnet.three.availability_zone
      ephemeral               = true
      block_device_os         = "/dev/nvme1n1"
      block_device_mount_path = "/var/lib/storageos/data/dev1"
    }
  }
}

#---------------------------------------------------------------
# Example to consume eks_blueprints_kubernetes_addons module
#---------------------------------------------------------------
module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Addons
  enable_amazon_eks_aws_ebs_csi_driver = true # used for etcd
  enable_ondat                         = true # default is false

  # Ondat addon configuration
  # ondat_create_cluster               = true                                   # whether to create the Ondat cluster
  # ondat_etcd_endpoints               = []                                     # etcd cluster endpoints
  # ondat_etcd_ca                      = ""                                     # etcd cluster CA (default autogenerated)
  # ondat_etcd_cert                    = ""                                     # etcd cluster cert (default autogenerated)
  # ondat_etcd_key                     = ""                                     # etcd cluster key (default autogenerated)
  # ondat_admin_username               = "storageos"                            # ondat API username
  # ondat_admin_password               = "storageos"                            # ondat API password
  # ondat_helm_config                  = {}                                     # additional/override Helm parameters
}
