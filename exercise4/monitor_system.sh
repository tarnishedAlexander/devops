#!/bin/bash

# Script simple de monitoreo de sistema
# Monitorea: CPU, RAM y Disco
# Registra alertas y envía correo si se exceden límites
# Con colores e histórico diario de métricas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
ALERTS_LOG="${SCRIPT_DIR}/alerts.log"
ENV_FILE="${WORKSPACE_DIR}/.env"
SEND_EMAIL="${SCRIPT_DIR}/send_email.py"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Límites (%)
CPU_LIMIT=80
RAM_LIMIT=80
DISK_LIMIT=80

# Fecha para el histórico diario
TODAY=$(date '+%Y%m%d')
METRICS_LOG="${SCRIPT_DIR}/metrics_${TODAY}.log"

# Cargar configuración
if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
fi

# Función para obtener CPU
get_cpu() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}'
}

# Función para obtener RAM
get_ram() {
    free -m | awk 'NR==2 {printf "%.0f", ($3 / $2) * 100}'
}

# Función para obtener DISCO
get_disk() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Función para mostrar métrica con color
show_metric() {
    local name="$1"
    local value="$2"
    local limit="$3"
    
    if (( value > limit )); then
        echo -e "${RED}✗ $name: ${value}%${NC} (límite: ${limit}%)"
        return 1
    else
        echo -e "${GREEN}✓ $name: ${value}%${NC} (límite: ${limit}%)"
        return 0
    fi
}

# Obtener métricas
CPU=$(get_cpu)
RAM=$(get_ram)
DISK=$(get_disk)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_LOG=$(date '+%Y-%m-%d %H:%M:%S')

# Guardar en histórico diario
echo "[$TIMESTAMP_LOG] CPU: ${CPU}% | RAM: ${RAM}% | DISCO: ${DISK}%" >> "$METRICS_LOG"

# Mostrar en terminal con colores
echo ""
echo -e "${YELLOW}=== MONITOREO DE SISTEMA ===${NC}"
echo "Hora: $TIMESTAMP"
echo ""

# Variables para alertas
ALERTS=""
HAS_ALERTS=0

# Validar CPU
if ! show_metric "CPU" "$CPU" "$CPU_LIMIT"; then
    ALERTS+="• CPU: ${CPU}% (límite: ${CPU_LIMIT}%)\n"
    echo "[$TIMESTAMP_LOG] ALERTA: CPU ALTA - ${CPU}%" >> "$ALERTS_LOG"
    HAS_ALERTS=1
fi

# Validar RAM
if ! show_metric "RAM" "$RAM" "$RAM_LIMIT"; then
    ALERTS+="• RAM: ${RAM}% (límite: ${RAM_LIMIT}%)\n"
    echo "[$TIMESTAMP_LOG] ALERTA: RAM ALTA - ${RAM}%" >> "$ALERTS_LOG"
    HAS_ALERTS=1
fi

# Validar DISCO
if ! show_metric "DISCO" "$DISK" "$DISK_LIMIT"; then
    ALERTS+="• DISCO: ${DISK}% (límite: ${DISK_LIMIT}%)\n"
    echo "[$TIMESTAMP_LOG] ALERTA: DISCO LLENO - ${DISK}%" >> "$ALERTS_LOG"
    HAS_ALERTS=1
fi

echo ""

# Mostrar estado general
if (( HAS_ALERTS == 1 )); then
    echo -e "${RED}⚠️  Se detectaron alertas${NC}"
    echo ""
else
    echo -e "${GREEN}✓ Todos los recursos dentro de los límites${NC}"
    echo ""
fi

# Enviar correo si hay alertas
if (( HAS_ALERTS == 1 )); then
    if [[ -f "$SEND_EMAIL" ]] && [[ -n "${EMAIL_TO:-}" ]] && [[ -n "${EMAIL_PASSWORD:-}" ]]; then
        echo -e "${YELLOW}📧 Enviando alerta por correo...${NC}"
        echo -e "$ALERTS" | python3 "$SEND_EMAIL" "$EMAIL_TO" "$EMAIL_FROM" "$EMAIL_PASSWORD" 2>&1
    else
        echo -e "${YELLOW}⚠️  Correo no configurado (revisa .env)${NC}"
    fi
fi

echo -e "${YELLOW}📊 Histórico guardado en: $METRICS_LOG${NC}"
echo ""
