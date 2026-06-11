output "controller_public_ip" {
  value = aws_instance.controller.public_ip
}

output "controller_private_ip" {
  value = aws_instance.controller.private_ip
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "worker_private_ip" {
  value = aws_instance.worker.private_ip
}

output "ssh_controller" {
  value = "ssh -i <YOUR_KEY.pem> ubuntu@${aws_instance.controller.public_ip}"
}

output "ssh_worker" {
  value = "ssh -i <YOUR_KEY.pem> ubuntu@${aws_instance.worker.public_ip}"
}

output "slurm_smoke_tests" {
  value = [
    "ssh ubuntu@${aws_instance.controller.public_ip}",
    "sinfo",
    "scontrol show node slurm-gpu-1",
    "srun -N1 -w slurm-gpu-1 hostname",
    "srun -N1 --gres=gpu:1 -w slurm-gpu-1 nvidia-smi"
  ]
}

output "cost_cleanup_reminder" {
  value = "Run terraform destroy when finished. GPU EC2 and the extra shared EBS volume are the main cost items."
}
