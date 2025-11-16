#!/bin/bash

# Función para enviar alertas por correo usando Python
send_email_alert() {
    local service=$1
    local timestamp=$2
    
    # Obtener el directorio del script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Usar Python para enviar el correo
    python3 "$SCRIPT_DIR/send_email.py" "$service" "$EMAIL_TO" "$EMAIL_FROM" "$EMAIL_PASSWORD"
}

# Cargar variables de entorno desde el archivo .env
# Buscar .env en el directorio actual, en el del script, o en directorios padres
ENV_FILE=""
for dir in "." "$(dirname "${BASH_SOURCE[0]}")" "$(dirname "${BASH_SOURCE[0]}")/.." /workspace; do
    if [ -f "$dir/.env" ]; then
        ENV_FILE="$dir/.env"
        break
    fi
done

if [ -n "$ENV_FILE" ]; then
    set -a  # Exportar todas las variables
    source "$ENV_FILE"
    set +a
    echo "✓ Archivo .env cargado desde: $ENV_FILE"
else
    echo "⚠ ADVERTENCIA: Archivo .env no encontrado"
    echo "Se buscó en:"
    echo "  - Directorio actual"
    echo "  - Directorio del script"
    echo "  - Directorio padre"
    echo "  - /workspace"
fi

# Validar que se proporcione un parámetro
if [ $# -eq 0 ]; then
    echo "Error: Debe proporcionar el nombre del servicio como parámetro"
    echo "Uso: ./check_service.sh nombre_del_servicio"
    echo "Ejemplo: ./check_service.sh nginx"
    exit 1
fi

SERVICE_NAME=$1
LOG_FILE="service_status.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if systemctl is-active --quiet "$SERVICE_NAME"; then
    STATUS="activo"
    MESSAGE="✓ El servicio '$SERVICE_NAME' está ACTIVO"
else
    STATUS="inactivo"
    MESSAGE="⚠ ALERTA: El servicio '$SERVICE_NAME' está INACTIVO"
fi

echo "$MESSAGE"

echo "[$TIMESTAMP] Servicio: $SERVICE_NAME | Estado: $STATUS" >> "$LOG_FILE"

if [ "$STATUS" = "inactivo" ]; then
    echo "[$TIMESTAMP] ALERTA: El servicio '$SERVICE_NAME' no está disponible" >> "$LOG_FILE"
    
    # Verificar si las variables de entorno de correo están configuradas
    if [ -z "$EMAIL_TO" ] || [ -z "$EMAIL_FROM" ]; then
        echo "⚠ ADVERTENCIA: Variables de correo no configuradas. Configure EMAIL_TO y EMAIL_FROM"
    else
        send_email_alert "$SERVICE_NAME" "$TIMESTAMP"
    fi
    
    exit 1
fi

exit 0
