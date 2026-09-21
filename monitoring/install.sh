#!/usr/bin/env bash
# Install kube-prometheus-stack into the kind cluster
set -euo pipefail

NS="${MONITORING_NS:-monitoring}"
CHART_VERSION="${PROM_STACK_VERSION:-65.1.0}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace "${NS}" \
  --version "${CHART_VERSION}" \
  --values "$(dirname "$0")/values.yaml" \
  --wait --timeout 10m

echo "Grafana: kubectl port-forward -n ${NS} svc/kube-prometheus-stack-grafana 3000:80"
echo "Default login often admin / prom-operator (override via values / Vault in prod)"
