#!/bin/bash

# Script de prueba para simular alertas altas
# Temporal para demostración

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TODAY=$(date '+%Y%m%d')
METRICS_LOG="${SCRIPT_DIR}/metrics_${TODAY}.log"
ALERTS_LOG="${SCRIPT_DIR}/alerts.log"
SEND_EMAIL="${SCRIPT_DIR}/send_email.py"
ENV_FILE="${WORKSPACE_DIR}/.env"

# Cargar configuración del .env global
if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
fi

# Simular valores altos
CPU=85
RAM=90
DISK=95

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Guardar en histórico
echo "[$TIMESTAMP] CPU: ${CPU}% | RAM: ${RAM}% | DISCO: ${DISK}%" >> "$METRICS_LOG"

# Mostrar en terminal
echo ""
echo -e "${YELLOW}=== MONITOREO DE SISTEMA (SIMULADO) ===${NC}"
echo "Hora: $TIMESTAMP"
echo ""

# Mostrar con colores
echo -e "${RED}✗ CPU: ${CPU}% (límite: 80%)${NC}"
echo "[$TIMESTAMP] ALERTA: CPU ALTA - ${CPU}%" >> "$ALERTS_LOG"

echo -e "${RED}✗ RAM: ${RAM}% (límite: 80%)${NC}"
echo "[$TIMESTAMP] ALERTA: RAM ALTA - ${RAM}%" >> "$ALERTS_LOG"

echo -e "${RED}✗ DISCO: ${DISK}% (límite: 80%)${NC}"
echo "[$TIMESTAMP] ALERTA: DISCO LLENO - ${DISK}%" >> "$ALERTS_LOG"

echo ""
echo -e "${RED}⚠️  Se detectaron alertas${NC}"
echo ""

# Intentar enviar correo
ALERTS="• CPU: ${CPU}% (límite: 80%)\n• RAM: ${RAM}% (límite: 80%)\n• DISCO: ${DISK}% (límite: 80%)"

if [[ -f "$SEND_EMAIL" ]] && [[ -n "${EMAIL_TO:-}" ]] && [[ -n "${EMAIL_PASSWORD:-}" ]]; then
    echo -e "${YELLOW}📧 Intentando enviar alerta por correo...${NC}"
    echo -e "$ALERTS" | python3 "$SEND_EMAIL" "$EMAIL_TO" "$EMAIL_FROM" "$EMAIL_PASSWORD"
else
    echo -e "${YELLOW}⚠️  Correo no configurado (revisa /workspace/.env)${NC}"
    [[ -z "${EMAIL_TO:-}" ]] && echo "   - EMAIL_TO no definido"
    [[ -z "${EMAIL_PASSWORD:-}" ]] && echo "   - EMAIL_PASSWORD no definido"
fi

echo ""
echo -e "${YELLOW}📊 Histórico guardado en: $METRICS_LOG${NC}"
echo ""
