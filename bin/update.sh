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

CURRENT_IP_FILE="/var/lib/update-cloudflare-dns/current_ip.txt"  # Ruta del archivo donde se guarda la IP

# Leer DNS_NAMES desde la variable de entorno y separarla en un arreglo
IFS=',' read -ra DNS_ARRAY <<< "$DNS_NAMES"

# Obtener la IP actual
NEW_IP=$(curl -s http://ifconfig.me)

# Si el archivo con la IP actual no existe, lo creamos
if [ ! -f "$CURRENT_IP_FILE" ]; then
    echo "$NEW_IP" > "$CURRENT_IP_FILE"
    echo "Archivo de IP creado con la IP actual: $NEW_IP"
    exit 0
fi

# Leemos la IP guardada en el archivo
SAVED_IP=$(cat "$CURRENT_IP_FILE")

# Si la IP ha cambiado, realizamos la actualización
if [ "$NEW_IP" != "$SAVED_IP" ]; then
    echo "La IP ha cambiado. Actualizando los registros DNS..."

    # Iteramos sobre los registros y los actualizamos
    for DNS_NAME in "${DNS_ARRAY[@]}"; do
        # Obtenemos el Record ID del registro A para cada nombre de dominio
        RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DNS_NAME" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" | jq -r '.result[0].id')

        # Si encontramos el Record ID, procedemos a actualizarlo
        if [ "$RECORD_ID" != "null" ]; then
            echo "Actualizando registro DNS: $DNS_NAME"

            # Realizamos la actualización del registro A con la nueva IP
            curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"A\",\"name\":\"$DNS_NAME\",\"content\":\"$NEW_IP\",\"ttl\":120,\"proxied\":false}"

            echo "Registro DNS $DNS_NAME actualizado a la nueva IP: $NEW_IP"
        else
            echo "No se encontró el registro para $DNS_NAME"
        fi
    done

    # Guardamos la nueva IP en el archivo
    echo "$NEW_IP" > "$CURRENT_IP_FILE"
    echo "IP actualizada en el archivo."
else
    echo "La IP no ha cambiado. No se necesita actualizar."
fi

