#!/bin/bash

# Verificar que las variables de entorno necesarias estén definidas
if [ -z "$ZONE_ID" ]; then
  echo "ERROR: ZONE_ID no está definida."
  exit 1
fi

if [ -z "$API_TOKEN" ]; then
  echo "ERROR: API_TOKEN no está definida."
  exit 1
fi

if [ -z "$DNS_NAMES" ]; then
  echo "ERROR: DNS_NAMES no está definida."
  exit 1
fi

# Obtener la IP pública actual
CURRENT_IP=$(curl -s http://ifconfig.me)

# Leer DNS_NAMES desde la variable de entorno y separarla en un arreglo
IFS=',' read -ra DNS_ARRAY <<< "$DNS_NAMES"

# Iterar sobre cada nombre DNS
for DNS_NAME in "${DNS_ARRAY[@]}"; do
  echo "Procesando: $DNS_NAME"

  # Consultar el registro DNS en Cloudflare
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNS_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo "$RESPONSE" | jq -r '.result[0].id')
  CF_IP=$(echo "$RESPONSE" | jq -r '.result[0].content')

  if [ "$RECORD_ID" == "null" ]; then
    echo "ERROR: No se encontró el registro para $DNS_NAME"
    continue
  fi

  if [ "$CURRENT_IP" != "$CF_IP" ]; then
    echo "La IP ha cambiado (Cloudflare: $CF_IP, Actual: $CURRENT_IP). Actualizando..."

    UPDATE_RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$DNS_NAME\",\"content\":\"$CURRENT_IP\",\"ttl\":120,\"proxied\":false}")

    if echo "$UPDATE_RESULT" | jq -e '.success' | grep -q true; then
      echo "✔ Registro DNS actualizado para $DNS_NAME"
    else
      echo "❌ Error actualizando $DNS_NAME"
    fi
  else
    echo "La IP no ha cambiado para $DNS_NAME. No se actualiza."
  fi

done
