#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?environment is required}"
IMAGE_NAME="${2:?image name is required}"
IMAGE_TAG="${3:?image tag is required}"

echo "Promoting ${IMAGE_NAME}:${IMAGE_TAG} to ${ENVIRONMENT}"

if [[ -n "${KUBECONFIG:-}" ]] || [[ -n "${KUBE_CONFIG_DATA:-}" ]]; then
  helm upgrade --install springboot-poc helm/springboot-poc     --set image.repository="${IMAGE_NAME}"     --set image.tag="${IMAGE_TAG}"     --namespace "${ENVIRONMENT}"     --create-namespace
else
  echo "No Kubernetes credentials found; running deployment validation only."
  helm lint helm/springboot-poc
  helm template springboot-poc helm/springboot-poc     --set image.repository="${IMAGE_NAME}"     --set image.tag="${IMAGE_TAG}" >/dev/null
fi
