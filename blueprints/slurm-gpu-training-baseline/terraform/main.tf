locals {
  name = var.name

  common_tags = merge(var.tags, {
    Name = local.name
  })
}

data "aws_ami" "ubuntu_controller" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ssm_parameter" "dlami" {
  name = var.dlami_ssm_parameter
}

resource "random_password" "munge_key" {
  length  = 32
  special = true
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-${var.az}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "slurm" {
  name        = "${local.name}-sg"
  description = "Slurm baseline lab security group"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.slurm.id
  description       = "SSH from operator"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.allowed_ssh_cidr
}

resource "aws_vpc_security_group_ingress_rule" "internal_all" {
  count             = var.create_default_dlami_sg_rules ? 1 : 0
  security_group_id = aws_security_group.slurm.id
  description       = "Allow all internal traffic inside the lab VPC for Slurm/NFS/NCCL demo"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.slurm.id
  description       = "Outbound internet access for package/model downloads"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ebs_volume" "shared" {
  availability_zone = var.az
  size              = var.shared_gib
  type              = "gp3"
  encrypted         = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-shared"
  })
}

resource "aws_instance" "controller" {
  ami                         = data.aws_ami.ubuntu_controller.id
  instance_type               = var.controller_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.slurm.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  private_ip                  = var.controller_private_ip

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data/controller.sh", {
    cluster_name        = local.name
    vpc_cidr            = var.vpc_cidr
    munge_key           = random_password.munge_key.result
    worker_name         = "slurm-gpu-1"
    worker_private_ip   = var.worker_private_ip
    worker_cpus         = var.worker_cpus
    worker_real_memory  = var.worker_real_memory_mb
    worker_gpu_count    = var.worker_gpu_count
  })

  root_block_device {
    volume_size           = var.controller_root_gib
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-controller"
    Role = "slurm-controller-nfs"
  })
}

resource "aws_volume_attachment" "shared" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.shared.id
  instance_id = aws_instance.controller.id
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ssm_parameter.dlami.value
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.slurm.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  private_ip                  = var.worker_private_ip

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user-data/worker.sh", {
    cluster_name          = local.name
    munge_key             = random_password.munge_key.result
    controller_name       = "slurm-controller"
    controller_private_ip = var.controller_private_ip
    worker_name           = "slurm-gpu-1"
    worker_cpus           = var.worker_cpus
    worker_real_memory    = var.worker_real_memory_mb
    worker_gpu_count      = var.worker_gpu_count
  })

  root_block_device {
    volume_size           = var.worker_root_gib
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  dynamic "instance_market_options" {
    for_each = var.worker_use_spot ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price                      = var.worker_spot_max_price == "" ? null : var.worker_spot_max_price
        instance_interruption_behavior = "terminate"
        spot_instance_type             = "one-time"
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-worker-gpu-1"
    Role = "slurm-gpu-worker"
  })
}
