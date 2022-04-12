# Ondat add-on for EKS Blueprints

## Introduction

[Ondat](https://ondat.io) is a highly scalable Kubernetes data plane that
provides stateful storage for applications. This blueprint installs Ondat
on Amazon Elastic Kubernetes Service (AWS EKS).

## Key features

1. Hyperconverged or centralised, Kubernetes-native storage on any infrastructure
1. Best-in-class performance, availability and security
1. Free tier with 1TiB of storage under management for up to 3 nodes
1. Larger storage capacity and NFS (RWX) support in paid product

Find out more in our [documentation](https://docs.ondat.io/docs/concepts/)!

## Examples

See [blueprints](blueprints/).

<!--- BEGIN_TF_DOCS --->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.8.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.9.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helm_addon"></a> [helm\_addon](#module\_helm\_addon) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_namespace.storageos](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.etcd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_context"></a> [addon\_context](#input\_addon\_context) | Input configuration for the addon | <pre>object({<br>    aws_caller_identity_account_id = string<br>    aws_caller_identity_arn        = string<br>    aws_eks_cluster_endpoint       = string<br>    aws_partition_id               = string<br>    aws_region_name                = string<br>    eks_cluster_id                 = string<br>    eks_oidc_issuer_url            = string<br>    eks_oidc_provider_arn          = string<br>    tags                           = map(string)<br>    irsa_iam_role_path             = optional(string)<br>    irsa_iam_permissions_boundary  = optional(string)<br>  })</pre> | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password for the Ondat admin user | `string` | `"storageos"` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Username for the Ondat admin user | `string` | `"storageos"` | no |
| <a name="input_create_cluster"></a> [create\_cluster](#input\_create\_cluster) | Determines if the StorageOSCluster and secrets should be created | `bool` | `true` | no |
| <a name="input_etcd_ca"></a> [etcd\_ca](#input\_etcd\_ca) | The PEM encoded CA for Ondat's etcd | `string` | `""` | no |
| <a name="input_etcd_cert"></a> [etcd\_cert](#input\_etcd\_cert) | The PEM encoded client certificate for Ondat's etcd | `string` | `""` | no |
| <a name="input_etcd_endpoints"></a> [etcd\_endpoints](#input\_etcd\_endpoints) | A list of etcd endpoints for Ondat | `list(string)` | <pre>[<br>  "https://storageos-etcd.storageos.svc.cluster.local:2379"<br>]</pre> | no |
| <a name="input_etcd_key"></a> [etcd\_key](#input\_etcd\_key) | The PEM encoded client key for Ondat's etcd | `string` | `""` | no |
| <a name="input_helm_config"></a> [helm\_config](#input\_helm\_config) | Helm provider config for the ondat addon | `any` | `{}` | no |
| <a name="input_irsa_permissions_boundary"></a> [irsa\_permissions\_boundary](#input\_irsa\_permissions\_boundary) | IAM Policy ARN for IRSA IAM role permissions boundary | `string` | `""` | no |
| <a name="input_irsa_policies"></a> [irsa\_policies](#input\_irsa\_policies) | IAM policy ARNs for Ondat IRSA | `list(string)` | `[]` | no |
| <a name="input_manage_via_gitops"></a> [manage\_via\_gitops](#input\_manage\_via\_gitops) | Determines if the add-on should be managed via GitOps. | `bool` | `false` | no |
<!--- END_TF_DOCS --->
