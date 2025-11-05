#!/usr/bin/env bash
# poc/check-prometheus.sh
# 簡易檢查腳本：驗證 monitoring namespace 裡的 pods、Grafana 與 Prometheus 基本可用性
# 需求: kubectl, curl

set -euo pipefail
ns=${1:-monitoring}
KUBECTL=${KUBECTL:-kubectl}
CURL=${CURL:-curl}

echo "POC health check for namespace: $ns"

command -v $KUBECTL >/dev/null 2>&1 || { echo "kubectl not found"; exit 2; }
command -v $CURL >/dev/null 2>&1 || { echo "curl not found"; exit 2; }

ok=0
fail=0

# 1) Pods status
echo "\n[1/4] Checking pods in namespace $ns..."
pods=$($KUBECTL -n $ns get pods --no-headers -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[*].ready 2>/dev/null || true)
if [ -z "$pods" ]; then
  echo "No pods found in namespace $ns"; fail=$((fail+1))
else
  echo "$pods"
  # crude check: any pod not in Running or Succeeded => warn
  not_running=$($KUBECTL -n $ns get pods --no-headers | awk '$3 != "Running" && $3 != "Completed" {print $1" "$3}') || true
  if [ -n "$not_running" ]; then
    echo "WARN: Some pods not running:"; echo "$not_running"; fail=$((fail+1))
  else
    echo "OK: All pods Running/Completed"; ok=$((ok+1))
  fi
fi

# helper to perform an HTTP check (with optional port-forward)
http_check() {
  local url=$1
  local pf_pid=$2
  local desc=$3
  echo "  Checking $desc -> $url"
  code=$($CURL -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || echo "000")
  if [ "$code" = "200" ] || [ "$code" = "302" ]; then
    echo "  OK ($code)"
    return 0
  else
    echo "  FAIL (http code $code)"
    return 1
  fi
}

# 2) Grafana access
echo "\n[2/4] Checking Grafana service..."
# try to locate grafana service name created by chart
g_svc=$($KUBECTL -n $ns get svc -l app.kubernetes.io/name=grafana --no-headers -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,PORT:.spec.ports[*].port,NAME2:.metadata.name 2>/dev/null | awk 'NR==1{print $1}') || true
if [ -z "$g_svc" ]; then
  # fallback common name
  g_svc=$(kubectl -n $ns get svc grafana --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || true)
fi
if [ -z "$g_svc" ]; then
  echo "Grafana service not found in namespace $ns"; fail=$((fail+1))
else
  echo "Found Grafana service: $g_svc"
  svc_json=$($KUBECTL -n $ns get svc $g_svc -o json)
  svc_type=$(echo "$svc_json" | grep '"type"' | head -n1 | sed -E 's/.*"type"\s*:\s*"([^"]+)".*/\1/')
  port=$(echo "$svc_json" | grep '"port"' | head -n1 | sed -E 's/.*"port"\s*:\s*([0-9]+).*/\1/')
  echo "Service type: $svc_type, port: ${port:-80}"
  if [[ "$svc_type" == "LoadBalancer" ]]; then
    ext_ip=$(echo "$svc_json" | grep -A2 '"status"' | grep '"ip"' | head -n1 | sed -E 's/.*"ip"\s*:\s*"([^"]+)".*/\1/' || true)
    if [ -n "$ext_ip" ]; then
      http_check "http://$ext_ip:${port:-80}" "" "Grafana (LoadBalancer)" && ok=$((ok+1)) || fail=$((fail+1))
    else
      echo "LoadBalancer has no external IP yet"; fail=$((fail+1))
    fi
  elif [[ "$svc_type" == "NodePort" ]]; then
    node_port=$(echo "$svc_json" | grep 'nodePort' | head -n1 | sed -E 's/.*nodePort\s*:\s*([0-9]+).*/\1/' || true)
    node_ip=$($KUBECTL get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || true)
    if [ -n "$node_ip" ] && [ -n "$node_port" ]; then
      http_check "http://$node_ip:$node_port" "" "Grafana (NodePort)" && ok=$((ok+1)) || fail=$((fail+1))
    else
      echo "Cannot determine node IP or nodePort"; fail=$((fail+1))
    fi
  else
    # ClusterIP or unknown, try port-forward
    echo "Using port-forward to access grafana (localhost:3000)"
    $KUBECTL -n $ns port-forward svc/$g_svc 3000:80 >/tmp/gf-forward.log 2>&1 &
    pf_pid=$!
    sleep 1
    http_check "http://localhost:3000" "$pf_pid" "Grafana (port-forward)" && ok=$((ok+1)) || fail=$((fail+1))
    kill $pf_pid >/dev/null 2>&1 || true
  fi
fi

# 3) Prometheus access and targets
echo "\n[3/4] Checking Prometheus service..."
p_svc=$($KUBECTL -n $ns get svc -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$p_svc" ]; then
  # fallback name used by kube-prometheus-stack
  p_svc=$($KUBECTL -n $ns get svc prometheus-kube-prometheus-prometheus --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || true)
fi
if [ -z "$p_svc" ]; then
  echo "Prometheus service not found in namespace $ns"; fail=$((fail+1))
else
  echo "Found Prometheus service: $p_svc"
  echo "Port-forwarding prometheus to localhost:9090"
  $KUBECTL -n $ns port-forward svc/$p_svc 9090:9090 >/tmp/pm-forward.log 2>&1 &
  pf_pid=$!
  sleep 1
  code=$($CURL -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:9090/api/v1/targets || echo "000")
  if [ "$code" = "200" ]; then
    echo "Prometheus API reachable (200)"
    # quick check for any UP target in the rendered HTML
    hits=$($CURL -s --max-time 5 http://localhost:9090/targets | grep -c 'up') || true
    echo "Targets page contains 'up' occurrences: ${hits:-0}"
    ok=$((ok+1))
  else
    echo "Prometheus API not reachable (http code $code)"; fail=$((fail+1))
  fi
  kill $pf_pid >/dev/null 2>&1 || true
fi

# 4) Alerting rules loaded (basic check)
echo "\n[4/4] Checking Prometheus rules presence..."
$KUBECTL -n $ns get prometheusrules --no-headers -o wide >/dev/null 2>&1 && echo "PrometheusRule CRDs present" && ok=$((ok+1)) || (echo "PrometheusRule CRD not found or none present"; fail=$((fail+1)))

# summary
echo "\nSummary: ok=$ok fail=$fail"
if [ "$fail" -gt 0 ]; then
  echo "One or more checks failed"; exit 1
else
  echo "All quick checks passed"; exit 0
fi
