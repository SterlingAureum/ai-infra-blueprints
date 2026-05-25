# vLLM Helm Chart

Deploy an OpenAI-compatible **vLLM** backend on Kubernetes.

This chart is the workload module used by the **AWS EKS vLLM NLB blueprint**. It is intended for GPU-backed inference workloads and can be exposed directly through an AWS Network Load Balancer by configuring the chart's `Service` as `LoadBalancer`.

This README focuses on the **chart layer**: values, installation, and runtime-related settings.  
For blueprint-level architecture and deployment flow, see:

```text
../../README.md
```

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

Notes:

- `image.tag: latest` is acceptable for lab usage, but production-oriented deployments should pin a fixed image tag.
- `service.annotations` is the key area for NLB behavior.
- In this blueprint, `ingress` is usually disabled because public exposure is handled directly by the Service.

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

The exact external address depends on the NLB resource created from the Service configuration.

---

## Notes

- This README is intentionally chart-focused and does not repeat the full blueprint-level deployment flow.

---

## Related Files

```text
values.yaml
prod-values.yaml
templates/
../../README.md
```
