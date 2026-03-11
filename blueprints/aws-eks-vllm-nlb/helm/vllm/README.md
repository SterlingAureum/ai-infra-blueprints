
# openclaw-vllm-openai (Helm Chart)

Deploy an **OpenAI-compatible vLLM backend** on Kubernetes. Works well on EKS GPU nodegroups and supports NLB Ingress.

## Prereqs
- Kubernetes cluster with GPU nodes
- NVIDIA device plugin installed (EKS GPU AMI + addon/operator)
- For NLB ingress: AWS Load Balancer Controller installed

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
  model: "meta-llama/Llama-3.1-8B-Instruct"
  dtype: "float16"
  maxModelLen: 16384
  tensorParallelSize: 1
  extraArgs:
    - --enable-auto-tool-choice
    - --tool-call-parser
    - llama3_json
    - --served-model-name
    - meta-llama/llama-3.1-8b-instruct
    - --gpu-memory-utilization
    - "0.90"
    - --attention-backend
    - FLASH_ATTN

service:
  type: LoadBalancer
  port: 80
  targetPort: 8000
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []
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
