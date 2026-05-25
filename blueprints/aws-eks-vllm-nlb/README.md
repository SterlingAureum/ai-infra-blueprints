# AWS EKS vLLM NLB Blueprint

Deploy vLLM on AWS EKS with public access through a **Network Load Balancer (NLB)**.

This blueprint is intended for scenarios where you want a more direct **Service-based** public entrypoint for an OpenAI-compatible inference backend running on Kubernetes.

This document explains the **solution-level design** of the NLB variant. For chart-specific parameters and installation details, see `helm/vllm/README.md`.

---

## When to Use This Blueprint

Choose this blueprint when you want:

- a simpler Layer 4 exposure model
- direct Service-to-load-balancer mapping
- fewer ingress-layer abstractions
- a more direct path from client to model service

This is often the more straightforward fit when the immediate goal is to expose the inference service with fewer moving parts.

---

## Directory Layout

```text
aws-eks-vllm-nlb/
├─ terraform/
└─ helm/
   └─ vllm/
```

### `terraform/`

The infrastructure layer typically covers:

- EKS cluster provisioning
- node group definition
- IAM and addon prerequisites
- cluster foundation required by the blueprint

### `helm/vllm/`

The workload layer typically covers:

- vLLM deployment manifests
- service definition
- NLB-oriented Service annotations where used
- values configuration for runtime behavior

---

## Architecture Overview

```text
Client
  -> AWS NLB
    -> Kubernetes Service (type: LoadBalancer)
      -> vLLM Pod(s)
        -> GPU Node(s)
```

Compared with the ALB blueprint, this access path is operationally more direct and usually involves fewer ingress-layer components.

---

## GPU Runtime Notes

GPU workloads require Kubernetes to advertise GPU resources correctly.

Common supporting components include:

- Node Feature Discovery
- NVIDIA Device Plugin

Example installation flow:

```bash
helm repo add nfd https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update
helm upgrade --install node-feature-discovery nfd/node-feature-discovery -n kube-system

helm repo add nvidia https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade --install nvidia-device-plugin nvidia/nvidia-device-plugin -n kube-system
```

Check GPU allocatable resources with:

```bash
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
```

---

## Endpoint Expectations

This blueprint is designed around exposing an OpenAI-compatible API surface from vLLM.

Typical API paths include:

```bash
GET  /v1/models
POST /v1/completions
POST /v1/chat/completions
```

The exact public address depends on the Kubernetes Service configuration and the NLB resource created for it.

---

## Secrets and Model Access

If your model is pulled from Hugging Face, a common pattern is to create a Kubernetes secret separately and reference it from the workload.

Example:

```bash
kubectl -n <namespace> create secret generic hf-token \
  --from-literal=token='<your_hf_token>'
```

This keeps credentials outside Git and avoids hardcoding secrets in committed chart values.

---

## Next Step

After reviewing this blueprint-level overview, continue with:

```text
terraform/
```

and then:

```text
helm/vllm/README.md
```
