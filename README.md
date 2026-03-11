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

### Not Included

- agent framework business logic
- application UI
- prompt orchestration
- product-layer workflow design
- full production platform hardening

In short, this repository is about the **inference backend infrastructure**, not the full application stack.

---

## Current Blueprints

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

These two blueprints should currently be treated as **parallel options**, not as replacements for one another.

---

## Repository Structure

```text
ai-infra-blueprints/
├─ blueprints/
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

### Structure Notes

- The root `README.md` explains repository purpose and blueprint selection.
- Each `blueprints/.../README.md` explains one deployment pattern at the solution level.
- Each `blueprints/.../helm/vllm/README.md` documents the Helm module itself.
- `docs/` can be used later for shared supporting documents if needed.

---

## What the Blueprints Deploy

The current blueprints are centered around the same core target:

- AWS EKS cluster
- GPU-capable worker nodes
- vLLM inference service
- OpenAI-compatible API endpoints
- public access through ALB or NLB depending on blueprint

Typical API paths include:

```bash
GET  /v1/models
POST /v1/completions
POST /v1/chat/completions
```

This makes the deployed backend usable by tools and gateways that expect an OpenAI-style API contract.

---

## Typical Workflow

A common workflow for a blueprint in this repository looks like this:

1. Provision AWS infrastructure with Terraform
2. Confirm cluster access with `kubectl`
3. Ensure GPU nodes are present
4. Install required GPU-related Kubernetes components
5. Deploy vLLM with Helm
6. Expose the service through the selected public access pattern
7. Verify the OpenAI-compatible endpoint

The exact implementation differs between the ALB and NLB blueprints, but the overall lifecycle is similar.

---

## GPU Runtime Prerequisites

GPU workloads on Kubernetes require the cluster to advertise GPU resources correctly.

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

If GPU values appear in the allocatable column, Kubernetes is detecting schedulable GPU resources correctly.

---

## Model Access and Secrets

vLLM may need to pull model artifacts from Hugging Face during startup.

A common pattern is to create a Kubernetes secret separately and reference it from the workload:

```bash
kubectl -n <namespace> create secret generic hf-token \
  --from-literal=token='<your_hf_token>'
```

This keeps credentials out of Git and avoids hardcoding secrets in committed chart values.

---

## Choosing ALB vs NLB

### Choose ALB when:

- you want an Ingress-oriented design
- you prefer Layer 7 routing semantics
- you expect more HTTP-oriented ingress features over time

### Choose NLB when:

- you want a simpler exposure path
- you prefer a more direct Service-to-load-balancer model
- you want fewer ingress abstractions in the first iteration

At the current stage of this repository, both should be viewed as valid reference patterns.

---

## Relationship to OpenClaw

This repository is infrastructure-focused and can be paired with an upstream gateway or agent runtime.

A typical separation looks like this:

- **this repository** provides the OpenAI-compatible inference backend
- **OpenClaw-related repositories** handle gateway, orchestration, or runtime integration

That separation keeps the infrastructure blueprint reusable beyond any single application stack.

---

## Planned Expansion

This repository is being built incrementally.

Possible future additions may include:

- additional cloud blueprints
- private or internal exposure patterns
- observability add-ons
- autoscaling refinements
- production hardening guidance
- reusable shared Helm or Terraform modules

The goal is to expand from working, testable infrastructure patterns rather than over-designing the repository too early.

---

## Current Status

This repository should currently be viewed as a **working blueprint collection**, not a finished production platform.

The current emphasis is:

- validating deployment patterns
- keeping the structure clean
- documenting practical infrastructure decisions
- leaving room for future expansion without major rewrites

---

## Suggested Reading Order

A practical reading order is:

1. this root `README.md`
2. `blueprints/aws-eks-vllm-alb/README.md` or `blueprints/aws-eks-vllm-nlb/README.md`
3. the corresponding `terraform/` directory
4. the corresponding `helm/vllm/README.md`

This keeps repository-level context, blueprint-level intent, and module-level details clearly separated.

---

## License

MIT
