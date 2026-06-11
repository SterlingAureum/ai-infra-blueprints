variable "region" {
  type    = string
  default = "us-east-2"
}

variable "name" {
  description = "Name prefix for all lab resources."
  type        = string
  default     = "slurm-gpu-lab"
}

variable "az" {
  description = "Single AZ for the low-cost lab. Keep controller and worker in the same AZ."
  type        = string
  default     = "us-east-2a"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.30.101.0/24"
}


variable "controller_private_ip" {
  description = "Static private IP for controller inside public_subnet_cidr."
  type        = string
  default     = "10.30.101.10"
}

variable "worker_private_ip" {
  description = "Static private IP for the first GPU worker inside public_subnet_cidr."
  type        = string
  default     = "10.30.101.20"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the lab. For real use, set this to your_public_ip/32."
  type        = string
}

variable "ssh_key_name" {
  description = "Existing EC2 key pair name."
  type        = string
}

variable "dlami_ssm_parameter" {
  description = "Public SSM parameter for the latest AWS Deep Learning OSS Nvidia Driver GPU PyTorch AMI."
  type        = string
  default     = "/aws/service/deeplearning/ami/x86_64/oss-nvidia-driver-gpu-pytorch-2.7-ubuntu-22.04/latest/ami-id"
}

variable "controller_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_instance_type" {
  description = "For lowest cost test, use g4dn.xlarge or g5.xlarge. For closer modern baseline, use g5.xlarge/g6.xlarge if available."
  type        = string
  default     = "g5.xlarge"
}

variable "worker_use_spot" {
  description = "Use Spot for the GPU worker. Recommended for this lab if interruption is acceptable."
  type        = bool
  default     = true
}

variable "worker_spot_max_price" {
  description = "Optional max Spot price. Empty means on-demand price cap."
  type        = string
  default     = ""
}

variable "controller_root_gib" {
  type    = number
  default = 60
}

variable "worker_root_gib" {
  type    = number
  default = 150
}

variable "shared_gib" {
  description = "Extra EBS volume attached to controller and exported as /shared via NFS."
  type        = number
  default     = 100
}

variable "worker_cpus" {
  description = "Slurm CPU count for the GPU worker. Match the selected instance type."
  type        = number
  default     = 4
}

variable "worker_real_memory_mb" {
  description = "Slurm RealMemory for the GPU worker. Use a conservative value lower than actual RAM."
  type        = number
  default     = 14000
}

variable "worker_gpu_count" {
  description = "Number of GPUs on the worker instance."
  type        = number
  default     = 1
}

variable "create_default_dlami_sg_rules" {
  description = "Open common lab ports inside the VPC. SSH is controlled separately by allowed_ssh_cidr."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to lab resources."
  type = map(string)
  default = {
    Project = "ai-infra-blueprints"
    Stack   = "slurm-gpu-training-baseline"
  }
}
