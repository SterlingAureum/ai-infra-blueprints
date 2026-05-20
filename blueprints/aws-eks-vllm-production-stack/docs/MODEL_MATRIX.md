# Model Matrix

This document tracks model-specific deployment examples tested with this blueprint.

| Model | Values File | Status | GPU Target | Notes |
|---|---|---|---|---|
| qwen25-14b-awq | `values/values-qwen25-14b-awq.yaml` | validated | 1 x 24GB GPU | Current recommended lab example |
| meta-llama/Llama-3-8B-Instruct | `values/llama-3-8b-instruct.yaml` | planned | 1 x 24GB GPU | Previously tested with earlier deployment path |
| qwen25-32b-awq | TBD | planned | 1 x 24GB+ GPU / multi-GPU TBD | Needs validation |
| 70B-class models | TBD | research | multi-GPU | Not validated in this repo yet |
