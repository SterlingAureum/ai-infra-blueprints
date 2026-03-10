
# AI Infra Blueprints

This repository contains infrastructure blueprints for running GPU-based AI inference workloads.
The goal is to provide a **clear, reproducible reference setup** for deploying an OpenAI-compatible
inference backend using Kubernetes.

The current blueprint focuses on:

- AWS EKS cluster
- GPU nodes
- vLLM inference server
- ALB ingress exposure
- OpenAI-compatible API endpoint

This repository intentionally keeps the scope limited to **infrastructure and deployment mechanics**.
Application frameworks such as OpenClaw or other agent runtimes are expected to connect to the
resulting OpenAI-compatible endpoint.

---

# Repository Structure

```
ai-infra-blueprints
│
├─ docs/
│
└─ blueprints/
   └─ aws-eks-vllm-alb/
      ├─ terraform/
      └─ helm/
         └─ vllm/
```

Each blueprint contains:

- Terraform infrastructure definitions
- Helm charts for workload deployment
- Minimal operational documentation

---

# Blueprint: AWS EKS + vLLM + ALB

This blueprint deploys a GPU inference backend using:

- AWS EKS
- GPU node groups
- vLLM inference server
- AWS ALB ingress
- OpenAI-compatible API

The deployed service exposes endpoints such as:

```
GET  /v1/models
POST /v1/chat/completions
```

These endpoints can be consumed by systems expecting the OpenAI API format.

---

# Deployment Overview

Typical workflow:

1. Provision EKS infrastructure using Terraform
2. Ensure GPU nodes are available
3. Install required Kubernetes GPU plugins
4. Deploy vLLM using Helm
5. Verify the inference endpoint

---

# GPU Plugin Setup

GPU nodes require Kubernetes plugins in order for the scheduler to detect and allocate GPU
resources correctly.

Install Node Feature Discovery:

```
helm repo add nfd https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update
helm upgrade --install node-feature-discovery nfd/node-feature-discovery -n kube-system
```

Install the NVIDIA device plugin:

```
helm repo add nvidia https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade --install nvidia-device-plugin nvidia/nvidia-device-plugin -n kube-system
```

These components enable Kubernetes to recognize GPU hardware and expose it as schedulable
resources.

---

# Verifying GPU Availability

After installing the plugins and starting GPU nodes, verify that Kubernetes detects the GPU
resources:

```
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
```

Example output:

```
NAME            GPU
ip-10-0-1-23    1
```

If GPU values appear in the `allocatable` column, the device plugin is functioning correctly.

GPU node labels in this blueprint are automatically applied through the node group configuration.
Manual labeling is not required.

---

# HuggingFace Token Secret

vLLM may download models from HuggingFace during startup.  
A Kubernetes secret can be created to provide the token securely.

Example:

```
kubectl -n ${namespace} create secret generic hf-token   --from-literal=token='hf_token'
```

This secret is referenced by the vLLM deployment to allow automatic model download.

Currently the secret is created separately rather than embedded directly inside the Helm chart.
This keeps credentials out of chart configuration and allows independent secret rotation.

---

# Notes

- Terraform state files are intentionally excluded from version control.
- This repository focuses on infrastructure only.
- Observability, multi-region deployment, and production hardening may be added in future
  iterations.

---

# Related Projects

This blueprint is often used together with:

**openclaw-deployment-lab**

That repository focuses on deploying and configuring the OpenClaw gateway while this repository
provides a compatible inference backend.

---

# License

MIT
