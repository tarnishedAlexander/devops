#!/bin/bash

REPO_URL="https://github.com/rayner-villalba-coderoad-com/clash-of-clan"
REPO_DIR="/var/www/clash-of-clan"
LOG_FILE="deploy.log"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1439458081367920811/hI1Y5wS890Hd6e_tg4YOf1L-ktCuWsZ_I2nAlhasQSKRnPNPP-c-EGJhffu2IVvyVugZ"
HOSTNAME=$(hostname)

# Función para enviar mensaje a Discord
send_discord_notification() {
    local status=$1
    local message=$2
    local color=$3
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Color: 3066993 = verde (éxito), 15158332 = rojo (error)
    local payload=$(cat <<EOF
{
    "embeds": [
        {
            "title": "🚀 Despliegue de Aplicación",
            "description": "**Estado:** $status",
            "color": $color,
            "fields": [
                {
                    "name": "Servidor",
                    "value": "$HOSTNAME",
                    "inline": true
                },
                {
                    "name": "Repositorio",
                    "value": "$REPO_URL",
                    "inline": false
                },
                {
                    "name": "Mensaje",
                    "value": "$message",
                    "inline": false
                },
                {
                    "name": "Timestamp",
                    "value": "$timestamp",
                    "inline": true
                }
            ]
        }
    ]
}
EOF
)
    
    curl -X POST -H 'Content-Type: application/json' \
        -d "$payload" \
        "$DISCORD_WEBHOOK" >> /dev/null 2>&1
}

handle_error() {
    local line=$1
    local error=$2
    echo "[$(date)] ERROR en línea $line: $error" | tee -a $LOG_FILE
    echo "[$(date)] Despliegue ABORTADO" | tee -a $LOG_FILE
    send_discord_notification "❌ FALLIDO" "Error en línea $line: $error" "15158332"
    exit 1
}

# Clonar o actualizar repositorio
echo "[$(date)] Clonando o actualizando repositorio..." | tee -a $LOG_FILE

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR" || handle_error $LINENO "No se pudo acceder a $REPO_DIR"
    if ! git pull origin main >> $LOG_FILE 2>&1; then
        handle_error $LINENO "git pull falló"
    fi
    echo "[$(date)] Repositorio actualizado" | tee -a $LOG_FILE
else
    mkdir -p $(dirname "$REPO_DIR") || handle_error $LINENO "No se pudo crear directorio $REPO_DIR"
    if ! git clone $REPO_URL $REPO_DIR >> $LOG_FILE 2>&1; then
        handle_error $LINENO "git clone falló"
    fi
    echo "[$(date)] Repositorio clonado" | tee -a $LOG_FILE
fi

# Copiar archivos a la carpeta pública
echo "[$(date)] Copiando archivos a /var/www/html..." | tee -a $LOG_FILE
if ! cp -r $REPO_DIR/* /var/www/html/ >> $LOG_FILE 2>&1; then
    handle_error $LINENO "No se pudieron copiar los archivos"
fi
echo "[$(date)] Archivos copiados" | tee -a $LOG_FILE

# Reiniciar servicio
echo "[$(date)] Reiniciando servicio..." | tee -a $LOG_FILE

SERVICE_RESTARTED=0

if command -v pm2 &> /dev/null; then
    if pm2 restart app >> $LOG_FILE 2>&1; then
        echo "[$(date)] Servicio pm2 reiniciado" | tee -a $LOG_FILE
        SERVICE_RESTARTED=1
    else
        echo "[$(date)] Advertencia: pm2 no pudo reiniciar la app" | tee -a $LOG_FILE
    fi
elif command -v systemctl &> /dev/null; then
    if systemctl restart nginx >> $LOG_FILE 2>&1; then
        echo "[$(date)] Servicio nginx reiniciado" | tee -a $LOG_FILE
        SERVICE_RESTARTED=1
    else
        handle_error $LINENO "systemctl restart nginx falló"
    fi
else
    handle_error $LINENO "No se encontró pm2 ni systemctl"
fi

if [ $SERVICE_RESTARTED -eq 0 ]; then
    handle_error $LINENO "No se pudo reiniciar ningún servicio"
fi

echo "[$(date)] Despliegue completado EXITOSAMENTE" | tee -a $LOG_FILE
send_discord_notification "✅ EXITOSO" "Despliegue completado correctamente" "3066993"
exit 0
