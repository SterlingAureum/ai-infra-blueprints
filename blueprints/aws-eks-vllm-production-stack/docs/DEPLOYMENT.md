# Deployment Notes

This document records the basic deployment flow for running vLLM Production Stack on EKS GPU nodes with a model-specific values file.

Current validated model:

- qwen25-14b-awq

Values file:

```text
../values/values-qwen25-14b-awq.yaml
```

## 1. Start From Blueprint Directory

```bash
cd blueprints/aws-eks-vllm-production-stack
```

## 2. Check Kubernetes Context

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

Make sure the current context points to the expected EKS cluster.

## 3. Check GPU Resources

Check whether GPU nodes are ready:

```bash
kubectl get nodes -o wide
```

Check allocatable GPU resources:

```bash
kubectl describe nodes | grep -i "nvidia.com/gpu" -A 5
```

Expected example:

```text
nvidia.com/gpu: 1
```

The value depends on the instance type and GPU count.

## 4. Check NVIDIA Device Plugin

```bash
kubectl get pods -A | grep -i nvidia
```

If the NVIDIA device plugin is missing or unhealthy, fix the GPU runtime layer before deploying vLLM.

## 5. Review Values File

```bash
sed -n '1,220p' values/qwen25-14b-awq.yaml
```

Before applying, check:

- model name
- served model ID
- image tag
- GPU request
- CPU and memory requests
- service type
- environment variables
- node selector or tolerations
- model token or secret references

Do not commit real tokens or private endpoints.

## 6. Create Namespace

Example namespace:

```bash
kubectl create namespace vllm
```

If it already exists, continue.

Check:

```bash
kubectl get namespace vllm
```

## 7. Create Secrets If Needed

If the model requires a token, create the secret manually.

Example placeholder:

```bash
kubectl create secret generic hf-token \
  -n vllm \
  --from-literal=token="<your-token>"
```

Skip this if your model access does not require a token.

## 8. Install or Upgrade vLLM Production Stack

Use the upstream production-stack Helm chart and this repository's values file.

Placeholder command:

```bash
helm upgrade --install <release-name> <vllm-production-stack-chart> \
  -n vllm \
  --create-namespace \
  -f values/qwen25-14b-awq.yaml
```

Replace:

```text
<release-name>
<vllm-production-stack-chart>
```

with the actual release name and chart reference used in your environment.

Example naming:

```text
release: qwen25-14b-awq
namespace: vllm
values: values/qwen25-14b-awq.yaml
```

## 9. Check Pods

```bash
kubectl get pods -n vllm -o wide
```

Watch startup:

```bash
kubectl get pods -n vllm -w
```

If a pod is not ready:

```bash
kubectl describe pod <pod-name> -n vllm
kubectl logs <pod-name> -n vllm
```

If there are multiple containers:

```bash
kubectl logs <pod-name> -n vllm -c <container-name>
```

## 10. Check Services

```bash
kubectl get svc -n vllm -o wide
```

For a LoadBalancer service, wait until the external address is assigned.

Describe the service if needed:

```bash
kubectl describe svc <service-name> -n vllm
```

Check:

- service type
- port and targetPort
- AWS load balancer annotations
- events
- external hostname

## 11. Test From Inside the Cluster

Optional internal test:

```bash
kubectl run curl-test \
  -n vllm \
  --rm -it \
  --image=curlimages/curl \
  --restart=Never \
  -- sh
```

Inside the curl pod:

```bash
curl "http://<service-name>.vllm.svc.cluster.local:<port>/v1/models"
```

## 12. Test External Endpoint

Set the endpoint:

```bash
export VLLM_BASE_URL="http://<load-balancer-dns-or-ip>"
```

List models:

```bash
curl "${VLLM_BASE_URL}/v1/models"
```

Then run chat completion tests from:

```text
OPENAI_API_TESTING.md
```

## 13. Cleanup

Uninstall the release:

```bash
helm uninstall <release-name> -n vllm
```

Delete namespace only if it contains no other workloads:

```bash
kubectl delete namespace vllm
```

## Quick Notes

Keep early validation simple:

- test `/v1/models` first
- keep `max_tokens` small
- use the exact model ID returned by `/v1/models`
- test vLLM directly before connecting OpenClaw
- avoid debugging OpenClaw and vLLM at the same time
