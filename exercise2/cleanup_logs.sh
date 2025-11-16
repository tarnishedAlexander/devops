#!/bin/bash

# Variables
LOG_DIR="/var/log"
BACKUP_DIR="/backup/logs"
DAYS=7
LOG_FILE="/var/log/cleanup_logs.log"
DATE=$(date +'%Y%m%d_%H%M%S')

# Crear directorio de backup si no existe
mkdir -p $BACKUP_DIR

# Registrar en log
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Iniciando limpieza de logs" >> $LOG_FILE

# Buscar y comprimir archivos con más de 7 días
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Buscando archivos con más de $DAYS días..." >> $LOG_FILE

find $LOG_DIR -maxdepth 1 -type f -mtime +$DAYS 2>/dev/null | while read file; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Encontrado: $file" >> $LOG_FILE
done

# Comprimir archivos antiguos
tar -czf $BACKUP_DIR/logs_backup_$DATE.tar.gz --mtime='7 days ago' -C $LOG_DIR . 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Compresión exitosa: logs_backup_$DATE.tar.gz" >> $LOG_FILE
    
    # Verificar compresión antes de eliminar
    if tar -tzf $BACKUP_DIR/logs_backup_$DATE.tar.gz > /dev/null 2>&1; then
        # Eliminar archivos originales con más de 7 días
        find $LOG_DIR -maxdepth 1 -type f -mtime +$DAYS -delete 2>/dev/null
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archivos originales eliminados" >> $LOG_FILE
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Fallo en verificación, archivos no eliminados" >> $LOG_FILE
    fi
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR en compresión" >> $LOG_FILE
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Limpieza completada" >> $LOG_FILE
