#!/bin/bash

# Script para crear logs falsos y probar cleanup_logs.sh

echo "=== Creando ambiente de pruebas ==="

# Crear directorios
TEST_DIR="$HOME/test_logs"
BACKUP_DIR="$HOME/test_backup"

mkdir -p "$TEST_DIR" "$BACKUP_DIR"
cd "$TEST_DIR"

echo "Directorio de prueba: $TEST_DIR"
echo "Directorio de backup: $BACKUP_DIR"
echo ""

# Crear logs recientes (2 días)
echo "Creando logs recientes (2 días atrás)..."
echo "INFO - Application started" > app.log
echo "ERROR - Database connection failed" > error.log
echo "GET /index.html 200 OK" > access.log
touch -d "2 days ago" app.log error.log access.log

# Crear logs antiguos (10 días)
echo "Creando logs antiguos (10 días atrás)..."
echo "Old app log entry" > old_app.log
echo "Old error entry" > old_error.log
touch -d "10 days ago" old_app.log old_error.log

# Crear logs de hoy
echo "Creando logs nuevos (hoy)..."
echo "nginx: worker process started" > nginx.log
echo "System check OK" > system.log

echo ""
echo "=== Estado inicial de archivos ==="
ls -lh "$TEST_DIR"

echo ""
echo "=== Creando script de prueba ==="

# Crear versión de prueba del script cleanup_logs.sh
cat > test_cleanup.sh << 'SCRIPT'
#!/bin/bash

LOG_DIR="$HOME/test_logs"
BACKUP_DIR="$HOME/test_backup"
DAYS=7
LOG_FILE="$HOME/test_cleanup.log"
DATE=$(date +'%Y%m%d_%H%M%S')

# Crear directorio de backup si no existe
mkdir -p $BACKUP_DIR

# Registrar en log
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Iniciando limpieza de logs" >> $LOG_FILE

# Buscar y mostrar archivos con más de 7 días
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Buscando archivos con más de $DAYS días..." >> $LOG_FILE

echo "Archivos encontrados:"
find $LOG_DIR -maxdepth 1 -type f -mtime +$DAYS 2>/dev/null | while read file; do
    echo "  - $file"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Encontrado: $file" >> $LOG_FILE
done

# Comprimir archivos antiguos
echo ""
echo "Comprimiendo archivos..."
tar -czf $BACKUP_DIR/logs_backup_$DATE.tar.gz -C $LOG_DIR old_app.log old_error.log 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Compresión exitosa: logs_backup_$DATE.tar.gz" >> $LOG_FILE
    
    # Verificar compresión antes de eliminar
    if tar -tzf $BACKUP_DIR/logs_backup_$DATE.tar.gz > /dev/null 2>&1; then
        # Eliminar archivos originales con más de 7 días
        find $LOG_DIR -maxdepth 1 -type f -mtime +$DAYS -delete 2>/dev/null
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archivos originales eliminados" >> $LOG_FILE
        echo "Archivos originales eliminados"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Fallo en verificación, archivos no eliminados" >> $LOG_FILE
    fi
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR en compresión" >> $LOG_FILE
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Limpieza completada" >> $LOG_FILE
SCRIPT

chmod +x test_cleanup.sh
echo "Script de prueba creado"

echo ""
echo "=== Ejecutando script de limpieza ==="
./test_cleanup.sh

echo ""
echo "=== Estado final de archivos ==="
ls -lh "$TEST_DIR"

echo ""
echo "=== Archivos en backup ==="
ls -lh "$BACKUP_DIR"

echo ""
echo "=== Contenido del archivo comprimido ==="
tar -tzf "$BACKUP_DIR"/logs_backup_*.tar.gz

echo ""
echo "=== Log de ejecución ==="
cat "$HOME/test_cleanup.log"

echo ""
echo "=== Prueba completada ==="
