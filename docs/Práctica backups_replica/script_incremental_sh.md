```bash
#!/bin/bash

# Variables
BACKUP_DIR="/home/yo/bkptattoo/incremental/"
TIMESTAMP=$(date +'%Y-%m-%d_%H:%M:%S')
BACKUP_FILE="$BACKUP_DIR/tattoo_incremental_$TIMESTAMP.sql.gz"
MAX_SIZE=1048576 # Tamaño máximo de 1 MB
REMOTO_USER="yo"
REMOTE_HOST="192.168.122.22"
REMOTE_DIR="/home/yo/bkptattoo/incremental2/"
DESTINO="$REMOTO_USER@$REMOTE_HOST:$REMOTE_DIR"
RSYNC_OPTS="-avz" # Opciones para rsync

# Backup incremental (usando .my.cnf para las credenciales)
if ! sudo mysqldump --single-transaction --quick --flush-logs tattoo | gzip >"$BACKUP_FILE"; then
  echo "Error: Fallo al crear el backup."
  exit 1
fi

# Verificar si el backup se creó correctamente
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Fallo al crear el backup."
  exit 1
fi

# Comprobamos si el archivo excede el tamaño máximo permitido
FILE_SIZE=$(stat -c%s "$BACKUP_FILE")
if [ "$FILE_SIZE" -gt $MAX_SIZE ]; then
  if ! split -b $MAX_SIZE "$BACKUP_FILE" "${BACKUP_FILE}_part_"; then
    echo "Error: Fallo al dividir el archivo."
    rm -f "$BACKUP_FILE"
    exit 1
  fi
  rm -f "$BACKUP_FILE"
  BACKUP_FILE="${BACKUP_FILE}_part_*" # Actualizar la variable para rsync
fi

# Sincronización con la máquina 2 (usando ssh-copy-id para acceso sin contraseña)
if ! rsync $RSYNC_OPTS "$BACKUP_FILE" "$DESTINO"; then
  echo "Error: Fallo en la sincronización con $REMOTE_HOST"
  exit 1
fi

# Limpieza local de copias incrementales antiguas
find "$BACKUP_DIR" -type f -mtime +7 -regex ".*\.sql\.gz" -delete

echo "Backup incremental realizado y sincronizado con $REMOTE_HOST"
exit 0
```
