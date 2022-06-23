# tflint-ignore: terraform_unused_declarations
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "eu-west-2"
}
variable "cluster_name" {
  description = "Name of cluster - used by Terratest for e2e test automation"
  type        = string
  default     = ""
}
