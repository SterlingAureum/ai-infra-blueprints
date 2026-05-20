# AWS EKS vLLM Production Stack Blueprint

This blueprint documents a practical EKS-based deployment path for running a GPU-backed, OpenAI-compatible vLLM inference backend using the official vLLM Production Stack Helm chart.

Current validated model example:

- qwen25-14b-awq

This blueprint focuses on the inference backend layer only. OpenClaw, agent orchestration, application UI, and full platform bootstrap are documented separately.

## Directory Layout

```text
blueprints/aws-eks-vllm-production-stack/
├─ README.md
├─ values/
│  └─ values-qwen25-14b-awq.yaml
└─ docs/
   ├─ DEPLOYMENT.md
   ├─ MODEL_MATRIX.md
   └─ OPENAI_API_TESTING.md
```

## Current Path

The current path is:

```text
EKS GPU node
  -> vLLM Production Stack
  -> qwen25-14b-awq values file
  -> OpenAI-compatible endpoint
  -> optional upstream gateway such as OpenClaw
```

The production-stack Helm chart is not vendored into this repository. This repository only keeps validated values files, deployment notes, and testing examples.

## Files

- `values/values-qwen25-14b-awq.yaml`
  - current validated model values file

- `docs/DEPLOYMENT.md`
  - deployment and validation steps

- `docs/OPENAI_API_TESTING.md`
  - curl checks for `/v1/models` and `/v1/chat/completions`

- `docs/MODEL_MATRIX.md`
  - model status and notes

## Usage

Start from this directory:

```bash
cd blueprints/aws-eks-vllm-production-stack
```

Review the values file:

```bash
sed -n '1,220p' values/qwen25-14b-awq.yaml
```

Then follow:

```text
docs/DEPLOYMENT.md
```

After deployment, validate the endpoint with:

```text
docs/OPENAI_API_TESTING.md
```

## Model Values

Model-specific Helm values are stored under:

```text
values/
```

Only mark a model as validated after it has been deployed and tested.

