data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  name = var.cluster_name

  tags = {
    Project = "openclaw"
    Owner   = "sterling"
  }

  # us-east-1 常见可用 AZ（足够做 demo）
  azs = ["us-east-1a", "us-east-1b"]

  # admin_principal_arn = var.admin_principal_arn != "" ? var.admin_principal_arn : data.aws_caller_identity.current.arn
  effective_admin_principal_arn = var.admin_principal_arn != "" ? var.admin_principal_arn : data.aws_iam_session_context.current.issuer_arn
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  map_public_ip_on_launch = true

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.enable_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # ALB Controller 依赖这些子网 tags（Blueprints 装好 controller 后就能直接用 Ingress）
  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  tags = local.tags
}

locals {
  node_subnet_ids = var.lab_public_nodes ? module.vpc.public_subnets : module.vpc.private_subnets
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # 这里用 registry 最新大版本范围；你也可以锁死某个版本
  version = "~> 20.0"

  tags = local.tags

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = local.node_subnet_ids

  # 本机 kubectl 要稳定访问：开 public endpoint
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  enable_cluster_creator_admin_permissions = false

  enable_irsa = true

  # 直接用 Access Entry（避免你之前手工 create-access-entry 的坑）
  access_entries = {
    admin = {
      principal_arn = local.effective_admin_principal_arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
    }

    gpu_spot = {
      name           = "gpu-spot"
      # ami_type       = "AL2_x86_64_GPU"
      ami_type       = "AL2023_x86_64_NVIDIA"
      capacity_type  = "SPOT"
      instance_types = ["g5.xlarge", "g5.2xlarge"]

      min_size     = 0
      max_size     = var.gpu_max
      desired_size = var.gpu_desired

      # 强烈建议：GPU 节点打标签 + 可选 taint（防止非 GPU workload 跑上来）
      labels = {
        "accelerator" = "gpu"
        "workload"    = "inference"
        "nvidia.com/gpu.present" = "true"
      }

      # 如果你希望“只有显式容忍的 Pod 才能上 GPU 节点”，开启 taints
      # taints = {
      #   gpu = {
      #     key    = "nvidia.com/gpu"
      #     value  = "true"
      #     effect = "NO_SCHEDULE"
      #   }
      # }

      # 关键：使用 Launch Template 来控制 root volume / 安全配置
      create_launch_template = true

      # Root disk（镜像解压 + 容器层 + 日志 + 少量缓存）
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.gpu_disk_gib
            volume_type           = "gp3"
            iops                  = 3000 # gp3 baseline; 可按需调
            throughput            = 125  # gp3 baseline; 可按需调
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 强制（生产安全默认）
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      # 可选：SSH 调试（生产一般关掉）
      key_name = var.ssh_key_name

      # kubelet 级别的默认：给 OS/容器预留资源，降低被驱逐概率
      # （EKS AMI 的 bootstrap 会吃这些参数）
      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=accelerator=gpu,workload=inference --system-reserved=cpu=200m,memory=1Gi,ephemeral-storage=10Gi --kube-reserved=cpu=200m,memory=1Gi,ephemeral-storage=10Gi --eviction-hard=memory.available<500Mi,nodefs.available<10%,imagefs.available<10%'"
    }

    gpu_ondemand = {
      name           = "gpu-ondemand"
      # ami_type       = "AL2_x86_64_GPU"
      ami_type       = "AL2023_x86_64_NVIDIA"
      capacity_type  = "ON_DEMAND"
      instance_types = ["g5.xlarge"]

      min_size     = 0
      max_size     = 1
      desired_size = 0

      labels = {
        "accelerator" = "gpu"
        "workload"    = "inference"
        "capacity"    = "ondemand"
      }

      create_launch_template = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 200
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint = "enabled"
        http_tokens   = "required"
      }
    }

  }
}

# 让 helm/k8s provider 直接连到新集群（用于 addons module）
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [null_resource.wait_for_eks_api]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [null_resource.wait_for_eks_api]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}

# resource "time_sleep" "wait_for_eks_api" {
#   depends_on      = [module.eks]
#   create_duration = "300s"
# }

resource "null_resource" "wait_for_eks_api" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
set -euo pipefail
aws eks wait cluster-active --name ${module.eks.cluster_name} --region ${var.region}
aws eks describe-cluster --name ${module.eks.cluster_name} --region ${var.region} --query 'cluster.status' --output text
EOT
  }

  # 可选：如果你经常 destroy/recreate，避免一些 provisioner 复用问题
  triggers = {
    cluster_id = module.eks.cluster_id
  }
}

# Blueprints Addons：一键装 ALB Controller（含 IRSA/IAM 权限）
module "eks_blueprints_addons" {
  count   = var.enable_addons ? 1 : 0
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true

  tags = local.tags

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  # depends_on = [time_sleep.wait_for_eks_api]
  depends_on = [null_resource.wait_for_eks_api]
}
