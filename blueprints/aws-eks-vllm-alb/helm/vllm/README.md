# vLLM Helm Chart

Deploy an OpenAI-compatible **vLLM** backend on Kubernetes.

This chart is the workload module used by the **AWS EKS vLLM ALB blueprint**. It is intended for GPU-backed inference workloads and supports public exposure through AWS Application Load Balancer by enabling Kubernetes Ingress configuration.

This README focuses on the **chart layer**: values, installation, and runtime-related settings.  
For blueprint-level architecture and deployment flow, see:

```text
../../README.md
```

---

## What This Chart Does

This chart is intended to deploy:

- a vLLM inference workload
- a Kubernetes Service for internal access
- optional ALB-facing Ingress resources
- optional persistence for model cache
- optional Hugging Face token integration through a Kubernetes secret

Typical API paths exposed by vLLM include:

```text
/v1/models
/v1/completions
/v1/chat/completions
```

---

## Prerequisites

Before installing this chart, make sure you already have:

- a Kubernetes cluster
- GPU-capable worker nodes
- NVIDIA device plugin installed
- a namespace prepared for the release
- model access credentials if your model requires Hugging Face authentication

For the ALB-based exposure pattern used in this blueprint, the cluster should also have the AWS Load Balancer Controller installed and working.

---

## Chart Layout

```text
vllm/
├─ templates/
├─ Chart.yaml
├─ values.yaml
├─ prod-values.yaml
└─ README.md
```

---

## Key Configuration Areas

The chart configuration is mainly organized around these concerns:

- `image`: container image repository and tag
- `resources`: CPU, memory, and GPU requests/limits
- `nodeSelector`: scheduling onto GPU nodes
- `vllm`: model and runtime arguments
- `service`: internal Kubernetes service settings
- `ingress`: ALB-facing ingress settings
- `persistence`: optional PVC for model cache
- `huggingface`: optional secret reference for token-based model access

---

## Minimal Example Values

Create a values file such as:

```text
prod-values.yaml
```

with content like this:

```yaml
image:
  repository: vllm/vllm-openai
  tag: "latest"  # pin a specific version in production

nodeSelector:
  accelerator: gpu

resources:
  limits:
    nvidia.com/gpu: 1
  requests:
    cpu: "2"
    memory: "8Gi"

vllm:
  model: "meta-llama/Llama-3-8b-instruct"
  dtype: "float16"
  maxModelLen: 4096
  tensorParallelSize: 1
  extraArgs:
    - "--gpu-memory-utilization"
    - "0.90"

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "alb"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  hosts:
    - host: ""
      paths:
        - path: /
          pathType: Prefix
```

Notes:

- `image.tag: latest` is acceptable for lab usage, but production-oriented deployments should pin a fixed image tag.
- `nodeSelector` should match the labels that actually exist on your GPU nodes.
- ALB-specific behavior is mainly controlled through the `ingress` block.

---

## Install

Example install command:

```bash
helm upgrade --install vllm . \
  -n openclaw \
  -f prod-values.yaml
```

If the namespace does not exist yet, create it first:

```bash
kubectl create namespace openclaw
```

---

## Persistence (Optional)

If you want to keep model cache data across pod restarts, enable persistence.

Example:

```yaml
persistence:
  enabled: true
  size: 200Gi
```

Use this only when persistent model cache is useful for your environment and storage class behavior is understood.

---

## Hugging Face Token (Optional)

If the model requires Hugging Face authentication, create a secret first:

```bash
kubectl create secret generic hf-token \
  --from-literal=token=<YOUR_HF_TOKEN> \
  -n openclaw
```

Then reference it in values:

```yaml
huggingface:
  tokenSecretName: hf-token
  tokenSecretKey: token
```

This keeps credentials outside the chart values committed to Git.

---

## Endpoints

Typical endpoints exposed by the workload include:

```text
GET  /v1/models
POST /v1/completions
POST /v1/chat/completions
```

The exact external URL depends on the ALB Ingress resource created from your values.

---

## What This README Covers

Use this chart README for:

- chart installation
- values configuration
- ingress settings for ALB exposure
- runtime tuning parameters
- persistence and secret integration

Use the blueprint README for:

- overall architecture
- Terraform and Helm relationship
- deployment flow across the full blueprint
- why this blueprint uses ALB instead of NLB

---

## Notes

- This README is intentionally chart-focused and does not repeat the full blueprint-level deployment flow.
- ALB exposure in this blueprint is implemented through Kubernetes Ingress rather than direct `LoadBalancer` Service exposure.
- Keep model-specific tuning in values files rather than hardcoding it into templates.

---

## Related Files

```text
values.yaml
prod-values.yaml
templates/
../../README.md
```
