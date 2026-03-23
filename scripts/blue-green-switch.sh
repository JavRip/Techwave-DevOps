#!/bin/bash
# blue-green-switch.sh
# Cambia el tráfico entre versiones blue y green
# Uso: ./scripts/blue-green-switch.sh [blue|green]

set -e
cd "$(dirname "$0")/.."

TARGET=$1

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "[ERROR] Uso: $0 [blue|green]"
  exit 1
fi

CURRENT=$(kubectl get svc techwave-service -n techwave \
  -o jsonpath='{.spec.selector.version}')

echo "[INFO] Versión actual: $CURRENT"
echo "[INFO] Cambiando a: $TARGET"

# Verificar que el deployment destino está healthy antes de cambiar
READY=$(kubectl get deployment techwave-app-$TARGET -n techwave \
  -o jsonpath='{.status.readyReplicas}')

if [[ "$READY" == "0" || -z "$READY" ]]; then
  echo "[ERROR] El deployment $TARGET no tiene réplicas ready. Abortando."
  exit 1
fi

echo "[OK] Deployment $TARGET tiene $READY réplicas ready"

# Hacer el switch
kubectl patch svc techwave-service -n techwave \
  --type=json \
  -p="[{\"op\":\"replace\",\"path\":\"/spec/selector/version\",\"value\":\"$TARGET\"}]"

echo "[OK] Tráfico dirigido a versión: $TARGET"

# Verificar que el switch fue exitoso
NEW=$(kubectl get svc techwave-service -n techwave \
  -o jsonpath='{.spec.selector.version}')
echo "[OK] Confirmado — Service apunta a: $NEW"