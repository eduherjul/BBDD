#!/bin/bash

# Variables
BACKUP_DIR="/home/yo/bkptattoo/completa"
TIMESTAMP=$(date +'%Y-%m-%d_%H:%M:%S')
BACKUP_FILE="$BACKUP_DIR/tattoo_completa_$TIMESTAMP.sql.gz"
REMOTO_USER="yo"
REMOTE_HOST="192.168.122.22"
REMOTE_DIR="/home/yo/bkptattoo/completa2/"
DESTINO="$REMOTO_USER@$REMOTE_HOST:$REMOTE_DIR"

# Backup completa
echo "Iniciando mysqldump..."
sudo mysqldump --all-databases --quick --flush-logs| pv -p | gzip >"$BACKUP_FILE"

# Verificar si el backup se generó correctamente
if [[ -f "$BACKUP_FILE" && -s "$BACKUP_FILE" ]]; then
  echo "Backup completado: $BACKUP_FILE"

  # Sincronización con la máquina 2
  echo "Iniciando rsync..."
  rsync -avz --remove-source-files "$BACKUP_FILE" "$DESTINO"
  echo "Transferencia completada."

else
  echo "Error: No se generó el archivo de backup correctamente."
  exit 1
fi
