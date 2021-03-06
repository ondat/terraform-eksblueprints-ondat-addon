# Ondat with External etcd

## Introduction

Ondat is a cloud native, software-defined storage for running containerized
applications in production, running in the cloud, on-prem and in
hybrid/multi-cloud environments. Ondat is free for personal use and offers
licenses for commercial usage. More information is available in
the [Ondat documentation](https://docs.ondat.io/docs/introduction/).

This module uses [ebs-bootstrap](https://github.com/ondat/etcd3-bootstrap)
and it's associated Terraform module to provision persistent storage via
EBS underneath EKS worker nodes in managed node groups.
[etcd3-terraform](https://github.com/ondat/etcd3-terraform) provides an
etcd cluster dedicated to Ondat.

The following is a high-level overview of the components generated by this module:

- 1x VPC with private and public subnets, internet gateway etc.
- 1x EKS cluster
- 3x EKS single-node managed node groups
- 3x etcd EC2 ASGs (non-kubernetes), each with one node
- 6x EBS volumes with daily automatic snapshots and 1 week retention for Ondat data (3x 10Gi, 3x 100Gi)
- 3x EBS volumes with daily automatic snapshots and 1 week retention for etcd data (32Gi each)
- Installation of Ondat via Helm on the EKS cluster

Estimated monthly cost of AWS resources: $534.32

## Installation

### Prerequisites

Make sure to have the following components installed on your local system:

- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Process

1. First, clone the repository:

```shell
git clone https://github.com/ondat/terraform-eksblueprints-ondat-addon.git
```

1. Initialise the Terraform module:

```shell
cd blueprints/getting-started
terraform init
```

1. Make any necessary adjustments to the `main.tf` file - eg. change region for destination
cluster and for the best level of performance, it's certainly worth adjusting instance
sizes and disk types and provisioned IOPS for higher performance (at higher cost).
1. Use Terraform to plan a deployment:

```shell
export AWS_REGION=us-east-1
export AWS_PROFILE=<YOUR_PROFILE>
export KUBE_CONFIG_FILE=~/.kube/config
terraform plan -var="aws_region=$AWS_REGION"
```

1. Review the plan and apply the deployment with Terraform:

```shell
terraform apply -var="aws_region=$AWS_REGION"
```

1. Use the AWS CLI to provision a kubeconfig profile for the cluster:

```shell
# The terraform output command can also be used to retrieve this
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
```

1. Check that the nodes have created and that Ondat is running:

```shell
kubectl get nodes
```

You should see 3 nodes in the list.

```shell
kubectl get pods -n storageos
```

You should see a `storageos-node` pod running on each node.

### Uninstall

1. To uninstall, destroy with Terraform - note that this will **permanently
delete the cluster and all data**. Destroying in layers will prevent missed
resources or errors.

```shell
terraform destroy -target="module.eks_blueprints_kubernetes_addons.module.ondat[0].module.helm_addon"
terraform destroy -target="module.eks_blueprints_kubernetes_addons"
terraform destroy -target="module.eks_blueprints" -target="module.etcd"
terraform destroy
```

1. You may also want to login via the AWS console or CLI and manually delete
any remaining EBS snapshots, they are not deleted as part of the destroy process.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.66.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.17.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_attached_ebs_one"></a> [attached\_ebs\_one](#module\_attached\_ebs\_one) | github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs | v0.1.2 |
| <a name="module_attached_ebs_three"></a> [attached\_ebs\_three](#module\_attached\_ebs\_three) | github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs | v0.1.2 |
| <a name="module_attached_ebs_two"></a> [attached\_ebs\_two](#module\_attached\_ebs\_two) | github.com/ondat/etcd3-bootstrap//terraform/modules/attached_ebs | v0.1.2 |
| <a name="module_eks_blueprints"></a> [eks\_blueprints](#module\_eks\_blueprints) | github.com/aws-ia/terraform-aws-eks-blueprints | n/a |
| <a name="module_eks_blueprints_kubernetes_addons"></a> [eks\_blueprints\_kubernetes\_addons](#module\_eks\_blueprints\_kubernetes\_addons) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons | n/a |
| <a name="module_etcd"></a> [etcd](#module\_etcd) | github.com/ondat/etcd3-terraform | v0.0.3 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.data1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.data2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.data3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_security_group.ondat_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ondat_access_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_access_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_api_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_etcd_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_gossip_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_gossip_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_grpc_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ondat_rwx_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.one](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.three](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.two](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster - used by Terratest for e2e test automation | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | EKS cluster ID |
| <a name="output_eks_managed_nodegroup_arns"></a> [eks\_managed\_nodegroup\_arns](#output\_eks\_managed\_nodegroup\_arns) | EKS managed node group arns |
| <a name="output_eks_managed_nodegroup_ids"></a> [eks\_managed\_nodegroup\_ids](#output\_eks\_managed\_nodegroup\_ids) | EKS managed node group ids |
| <a name="output_eks_managed_nodegroup_role_name"></a> [eks\_managed\_nodegroup\_role\_name](#output\_eks\_managed\_nodegroup\_role\_name) | EKS managed node group role name |
| <a name="output_eks_managed_nodegroup_status"></a> [eks\_managed\_nodegroup\_status](#output\_eks\_managed\_nodegroup\_status) | EKS managed node group status |
| <a name="output_eks_managed_nodegroups"></a> [eks\_managed\_nodegroups](#output\_eks\_managed\_nodegroups) | EKS managed node groups |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | VPC CIDR |
| <a name="output_vpc_private_subnet_cidr"></a> [vpc\_private\_subnet\_cidr](#output\_vpc\_private\_subnet\_cidr) | VPC private subnet CIDR |
| <a name="output_vpc_public_subnet_cidr"></a> [vpc\_public\_subnet\_cidr](#output\_vpc\_public\_subnet\_cidr) | VPC public subnet CIDR |
