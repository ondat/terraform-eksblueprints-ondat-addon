variable "helm_config" {
  type        = any
  description = "Helm provider config for the ondat addon"
  default     = {}
}

variable "manage_via_gitops" {
  type        = bool
  default     = false
  description = "Determines if the add-on should be managed via GitOps."
}

variable "addon_context" {
  type = object({
    aws_caller_identity_account_id = string
    aws_caller_identity_arn        = string
    aws_eks_cluster_endpoint       = string
    aws_partition_id               = string
    aws_region_name                = string
    eks_cluster_id                 = string
    eks_oidc_issuer_url            = string
    eks_oidc_provider_arn          = string
    tags                           = map(string)
    irsa_iam_role_path             = optional(string)
    irsa_iam_permissions_boundary  = optional(string)
  })
  description = "Input configuration for the addon"
}

variable "irsa_permissions_boundary" {
  type        = string
  default     = ""
  description = "IAM Policy ARN for IRSA IAM role permissions boundary"
}

variable "irsa_policies" {
  type        = list(string)
  default     = []
  description = "IAM policy ARNs for Ondat IRSA"
}

variable "create_cluster" {
  type        = bool
  default     = true
  description = "Determines if the StorageOSCluster and secrets should be created"
}

variable "etcd_endpoints" {
  type        = list(string)
  default     = ["https://storageos-etcd.storageos.svc.cluster.local:2379"]
  description = "A list of etcd endpoints for Ondat"
}

variable "etcd_ca" {
  type        = string
  default     = ""
  description = "The PEM encoded CA for Ondat's etcd"
}

variable "etcd_cert" {
  type        = string
  default     = ""
  description = "The PEM encoded client certificate for Ondat's etcd"
}

variable "etcd_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "The PEM encoded client key for Ondat's etcd"
}

variable "admin_username" {
  type        = string
  default     = "storageos"
  description = "Username for the Ondat admin user"
}

variable "admin_password" {
  type        = string
  default     = "storageos"
  sensitive   = true
  description = "Password for the Ondat admin user"
}
