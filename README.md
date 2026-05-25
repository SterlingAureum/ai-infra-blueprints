# AI Infra Blueprints

Reference infrastructure blueprints for running GPU-based AI inference backends on Kubernetes.

This repository focuses on the **infrastructure layer** for exposing OpenAI-compatible inference APIs. It is intended for scenarios where the model backend is deployed as a reusable platform component that can later be consumed by upstream systems such as OpenClaw, internal gateways, or custom AI applications.

At the current stage, the repository contains AWS EKS-based blueprints for deploying **vLLM on GPU nodes** with different public exposure patterns.

---

## Repository Scope

This repository is intentionally scoped to infrastructure delivery.

### Included

- Kubernetes-based AI inference infrastructure
- AWS EKS deployment patterns
- GPU node scheduling and runtime prerequisites
- Helm-based vLLM deployment
- OpenAI-compatible API exposure
- public access patterns through ALB or NLB

---

## Current Blueprints

### `blueprints/aws-eks-vllm-production-stack`

Deploy vLLM on AWS EKS GPU nodes using the official **vLLM Production Stack** Helm chart with model-specific values files.

Current validated model example:

- `qwen25-14b-awq`

Recommended when you prefer:

- using the upstream vLLM Production Stack chart
- keeping model-specific deployment values in this repository
- exposing a reusable OpenAI-compatible inference backend

### `blueprints/aws-eks-vllm-alb`

Deploy vLLM on AWS EKS behind an **Application Load Balancer (ALB)**.

Recommended when you prefer:

- Layer 7 HTTP/HTTPS ingress
- Kubernetes Ingress-based routing
- ALB-native integration patterns
- a more typical web-style entrypoint

### `blueprints/aws-eks-vllm-nlb`

Deploy vLLM on AWS EKS behind a **Network Load Balancer (NLB)**.

Recommended when you prefer:

- a simpler Layer 4 exposure model
- direct Service-based public access
- fewer ingress-layer moving parts
- a more direct path from client to model service

The ALB and NLB blueprints are kept as reference exposure patterns. The production-stack blueprint is the current recommended direction for model-serving work.

---

## Repository Structure

```text
ai-infra-blueprints/
├─ blueprints/
│  ├─ aws-eks-vllm-production-stack/
│  │  ├─ values/
│  │  ├─ docs/
│  │  └─ README.md
│  ├─ aws-eks-vllm-alb/
│  │  ├─ terraform/
│  │  ├─ helm/
│  │  └─ README.md
│  └─ aws-eks-vllm-nlb/
│     ├─ terraform/
│     ├─ helm/
│     └─ README.md
├─ docs/
└─ README.md
```

---

## Relationship to OpenClaw

This repository is infrastructure-focused and can be paired with an upstream gateway or agent runtime.

A typical separation looks like this:

- **this repository** provides the OpenAI-compatible inference backend
- **OpenClaw-related repositories** handle gateway, orchestration, or runtime integration

That separation keeps the infrastructure blueprint reusable beyond any single application stack.

---

## Suggested Reading Order

A practical reading order is:

1. this root `README.md`
2. `blueprints/aws-eks-vllm-production-stack/README.md`
3. `blueprints/aws-eks-vllm-production-stack/docs/DEPLOYMENT.md`
4. `blueprints/aws-eks-vllm-production-stack/docs/OPENAI_API_TESTING.md`

For the earlier reference patterns, read:

- `blueprints/aws-eks-vllm-alb/README.md`
- `blueprints/aws-eks-vllm-nlb/README.md`

This keeps the current production-stack path separate from the earlier ALB and NLB exposure examples.

---

## License

MIT
