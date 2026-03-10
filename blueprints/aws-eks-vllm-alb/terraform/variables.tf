variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "eks-openclaw-lab"
}

variable "cluster_version" {
  type    = string
  default = "1.33"
}

# Make your current unified identity (sterling-admin role) directly a Kubernetes administrator
variable "admin_principal_arn" {
  description = "Optional: IAM principal (role/user ARN) to grant EKS cluster admin access. If empty, the current Terraform caller identity is used."
  type        = string
  default     = ""

  validation {
    condition = (
      var.admin_principal_arn == "" ||
      can(regex("^arn:aws:iam::[0-9]{12}:(role|user)/.+$", var.admin_principal_arn))
    )
    error_message = "admin_principal_arn must be an IAM role/user ARN (arn:aws:iam::...), not an STS assumed-role ARN (arn:aws:sts::...)."
  }
}

# GPU nodes default to 0: no cost if not used
variable "gpu_desired" {
  type    = number
  default = 0
}

variable "gpu_max" {
  type    = number
  default = 1
}

variable "gpu_disk_gib" {
  type    = number
  default = 150
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "enable_addons" {
  type    = bool
  default = true
}

variable "cluster_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"] # You can do this for the demo first, then change to ["your-public-ip/32"] later
}

variable "lab_public_nodes" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}
