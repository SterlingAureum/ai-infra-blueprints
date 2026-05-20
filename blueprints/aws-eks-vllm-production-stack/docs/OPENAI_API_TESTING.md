# OpenAI-Compatible API Testing

This document provides simple curl checks for a vLLM OpenAI-compatible endpoint.

Current validated model:

- qwen25-14b-awq

Run these checks before connecting the endpoint to OpenClaw or another gateway.

## 1. Set Base URL

```bash
export VLLM_BASE_URL="http://<load-balancer-dns-or-ip>"
```

Do not add a trailing slash.

Good:

```text
http://example-nlb.amazonaws.com
```

Avoid:

```text
http://example-nlb.amazonaws.com/
```

## 2. Optional API Key

If your endpoint requires an API key:

```bash
export VLLM_API_KEY="<your-api-key>"
```

If the lab endpoint does not enforce authentication, use the no-key examples.

## 3. List Models

Without API key:

```bash
curl "${VLLM_BASE_URL}/v1/models"
```

With API key:

```bash
curl "${VLLM_BASE_URL}/v1/models" \
  -H "Authorization: Bearer ${VLLM_API_KEY}"
```

Expected model ID for the current example:

```text
qwen25-14b-awq
```

Use the exact model ID returned by `/v1/models` in later requests.

## 4. Chat Completion

Without API key:

```bash
curl "${VLLM_BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen25-14b-awq",
    "messages": [
      {
        "role": "user",
        "content": "Reply with one short sentence."
      }
    ],
    "max_tokens": 32,
    "temperature": 0
  }'
```

With API key:

```bash
curl "${VLLM_BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${VLLM_API_KEY}" \
  -d '{
    "model": "qwen25-14b-awq",
    "messages": [
      {
        "role": "user",
        "content": "Reply with one short sentence."
      }
    ],
    "max_tokens": 32,
    "temperature": 0
  }'
```

## 5. Slightly Larger Test

After the minimal test works:

```bash
curl "${VLLM_BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen25-14b-awq",
    "messages": [
      {
        "role": "user",
        "content": "Give me a short explanation of Kubernetes in one paragraph."
      }
    ],
    "max_tokens": 128,
    "temperature": 0.2
  }'
```

## 6. Common Issues

### Model ID mismatch

Symptom:

```text
model not found
Unknown model
The model does not exist
```

Check:

```bash
curl "${VLLM_BASE_URL}/v1/models"
```

Use the exact returned model ID.

### Context length or token budget error

Common causes:

- prompt is too long
- `max_tokens` is too high
- upstream gateway adds large context
- tool schemas consume many tokens

Fix:

- reduce prompt size
- reduce `max_tokens`
- test vLLM directly without gateway/tools

### Empty or hanging response

Check pods and logs:

```bash
kubectl get pods -n vllm -o wide
kubectl logs <pod-name> -n vllm
```

Also check service exposure:

```bash
kubectl get svc -n vllm -o wide
kubectl describe svc <service-name> -n vllm
```

### 401 or 403

Check whether the endpoint requires an API key.

Try the API-key version of the request.

### 404

Check the base URL and path:

```text
/v1/models
/v1/chat/completions
```

## 7. Before Connecting OpenClaw

Confirm these first:

```text
[ ] /v1/models works
[ ] /v1/chat/completions works
[ ] model ID is correct
[ ] max_tokens is conservative
[ ] API key behavior is clear
[ ] direct curl test works without OpenClaw
```

Only then configure OpenClaw or another upstream gateway.
