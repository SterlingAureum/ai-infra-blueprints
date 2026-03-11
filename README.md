# AI Infra Blueprints

Reference infrastructure blueprints for running GPU-based AI inference backends on Kubernetes.

This repository focuses on **infrastructure delivery**, not on agent runtime logic. Its purpose is to provide reproducible deployment patterns for exposing **OpenAI-compatible inference APIs** that can be consumed by upstream systems such as OpenClaw, internal gateways, or other AI application layers.

At the current stage, the repository contains AWS EKS-based blueprints for deploying **vLLM on GPU nodes** with different public exposure patterns.

---

## Scope

This repository is designed around a clear boundary:

- **Included**
  - Kubernetes-based AI inference infrastructure
  - AWS EKS cluster patterns
  - GPU node scheduling and runtime prerequisites
  - Helm-based vLLM deployment
  - OpenAI-compatible API exposure
  - Ingress / Load Balancer access patterns

- **Not included**
  - Agent framework business logic
  - Application UI
  - Prompt orchestration
  - Multi-model routing logic at the product layer
  - Full production platform hardening

In other words, this repo is the **inference backend infrastructure layer**, not the complete AI product stack.

---

## Current Blueprints

### 1. `blueprints/aws-eks-vllm-alb`
AWS EKS blueprint for exposing vLLM through **AWS Application Load Balancer (ALB)**.

This variant is suitable when you want:

- Layer 7 HTTP/HTTPS ingress
- Kubernetes Ingress-based routing
- ALB-native integration patterns
- A more typical web-style entrypoint

### 2. `blueprints/aws-eks-vllm-nlb`
AWS EKS blueprint for exposing vLLM through **AWS Network Load Balancer (NLB)**.

This variant is suitable when you want:

- A simpler Layer 4 exposure model
- Direct service exposure through a `LoadBalancer` service
- Fewer ingress-layer moving parts
- A practical alternative to ALB for inference access

---

## Repository Structure

```text
ai-infra-blueprints/
├─ blueprints/
│  ├─ aws-eks-vllm-alb/
│  │  ├─ terraform/
│  │  └─ helm/
│  └─ aws-eks-vllm-nlb/
│     ├─ terraform/
│     └─ helm/
├─ docs/
└─ README.md
```

Each blueprint is intended to keep a similar high-level shape:

- terraform/ for infrastructure provisioning

- helm/ for workload deployment

- local blueprint-specific notes where needed

This layout is meant to make future blueprints easy to add without restructuring the repository.

## What These Blueprints Deploy

The current blueprints are centered around the same core target:

- AWS EKS cluster

- GPU-capable worker nodes

- vLLM inference server

- OpenAI-compatible API endpoints

- Public access through ALB or NLB depending on blueprint

Typical endpoints exposed by the deployed inference backend include:

```bash
GET  /v1/models
POST /v1/completions
POST /v1/chat/completions
```

This makes the deployed service usable by tools and gateways that expect an OpenAI-style API contract.

---

## Typical Workflow

The usual workflow for a blueprint in this repository is:

1. Provision the AWS infrastructure with Terraform

2. Ensure GPU nodes are available in the cluster

3. Install required Kubernetes GPU-related components

4. Deploy vLLM with Helm

5. Expose the service through the selected access pattern

6. Verify the OpenAI-compatible API endpoint

## GPU Runtime Prerequisites

GPU workloads on Kubernetes require the cluster to recognize and advertise GPU resources correctly.

Typical supporting components include:

- Node Feature Discovery (NFD)

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

After installation, GPU allocatable resources can be checked with:

```bash
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
```

If GPU values appear in the allocatable column, Kubernetes is detecting schedulable GPU resources correctly.

## Model Access and Secrets

vLLM may need to pull model artifacts from Hugging Face during startup.

A common pattern is to create a Kubernetes secret separately and reference it from the workload:

```bash
kubectl -n <namespace> create secret generic hf-token \
  --from-literal=token='<your_hf_token>'
```

This repository intentionally keeps credentials outside the committed chart values so that:

- secrets are not stored in Git

- token rotation remains independent

- the chart stays reusable across environments

## Choosing ALB vs NLB

Both patterns are valid, but they serve slightly different operational preferences.

### Choose ALB when:

- you want an Ingress-oriented design

- you prefer Layer 7 routing semantics

- you expect more HTTP-oriented ingress features over time

### Choose NLB when:

- you want a simpler exposure path

- you prefer a more direct service-to-load-balancer model

- you want fewer ingress abstractions in the first iteration

At the current stage of this repository, these should be treated as parallel blueprint options, not as strict replacements for one another.

---

## Design Principles

This repository follows a few practical principles:

- Keep infrastructure concerns separate from application logic

- Prefer reproducible, minimal building blocks first

- Avoid unnecessary platform complexity in early versions

- Document working reference patterns before expanding scope

- Allow multiple access patterns (ALB / NLB) to coexist

---

## Planned Expansion

This repository is intentionally being built incrementally.

Possible future additions may include:

- additional cloud blueprints

- private/internal exposure patterns

- observability add-ons

- autoscaling refinements

- production hardening guidance

- versioned deployment notes

- multi-environment structure

- reusable shared Helm/Terraform modules

The goal is not to make the repository artificially broad too early, but to let it expand from working, testable infrastructure patterns.

---

## Relationship to OpenClaw

This repository is infrastructure-focused and pairs naturally with an upstream gateway or agent runtime.

For example, it can be used alongside:

- openclaw-deployment-lab

In that split:

- this repository provides the OpenAI-compatible inference backend

- OpenClaw-related repositories handle gateway / orchestration / runtime integration

That separation keeps the infrastructure blueprint reusable even outside of OpenClaw.

---

## Current Status

This repository should currently be viewed as a **working blueprint collection**, not a finished production platform.

The current emphasis is:

- validating deployment patterns

- keeping the structure clean

- documenting practical infrastructure decisions

- leaving room for future expansion without large rewrites

## License

MIT
