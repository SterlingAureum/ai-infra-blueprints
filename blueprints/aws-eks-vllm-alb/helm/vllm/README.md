
# openclaw-vllm-openai (Helm Chart)

Deploy an **OpenAI-compatible vLLM backend** on Kubernetes. Works well on EKS GPU nodegroups and supports ALB Ingress.

## Prereqs
- Kubernetes cluster with GPU nodes
- NVIDIA device plugin installed (EKS GPU AMI + addon/operator)
- For ALB ingress: AWS Load Balancer Controller installed

## Install
```bash
helm upgrade --install vllm openclaw-vllm-openai/ \
  -n openclaw --create-namespace
```

## Minimal production-ish values (example)
Create `prod-values.yaml`:
```yaml
image:
  repository: vllm/vllm-openai
  tag: "latest"   # pin in production

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

Install with:
```bash
helm upgrade --install vllm . -n openclaw -f prod-values.yaml
```

## Persistence (optional)
Enable PVC to cache models:
```yaml
persistence:
  enabled: true
  size: 200Gi
```

## HF token (optional)
```bash
kubectl create secret generic hf-token --from-literal=token=<YOUR_HF_TOKEN> -n openclaw
```
```yaml
huggingface:
  tokenSecretName: hf-token
  tokenSecretKey: token
```

## Endpoints
- `/v1/models`
- `/v1/chat/completions`
- `/v1/completions`
