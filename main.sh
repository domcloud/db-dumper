#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

TODAY=$(date +%F)
TMPDIR=/tmp/db-dumper
BASE_DIR="$SCRIPT_DIR/$TODAY"
MAX_SIZE_MB=512
RETENTION_DAYS=30

rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"

########################################
# 🔷 PostgreSQL Backup - Custom Format #
########################################

echo "[INFO] Starting PostgreSQL backup..."

# Get list of databases excluding templates
sudo -u postgres psql -Atc "SELECT datname FROM pg_database WHERE datistemplate = false;" | while read -r db; do
  echo "  → [$db]"
  DB_DIR="$BASE_DIR/pg-$db"
  TMP_DIR="$TMPDIR/pg-$db"
  rm -rf $TMP_DIR; mkdir -p $DB_DIR $TMP_DIR
  chown -R postgres:postgres $TMP_DIR
  chmod -R 0700 $TMP_DIR

  sudo -u postgres psql -d "$db" -Atc "
    SELECT n.nspname || '.' || c.relname
    FROM pg_stat_user_tables s
    JOIN pg_class c ON c.relname = s.relname AND c.relkind = 'r'
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE pg_total_relation_size(c.oid) < ${MAX_SIZE_MB} * 1024 * 1024;
  " | while read -r table; do
    schema=$(cut -d. -f1 <<< "$table")
    tab=$(cut -d. -f2 <<< "$table")
    echo "    → Dumping $table"
    (sudo -u postgres pg_dump -Fc -d "$db" -t "$table" -f "$TMP_DIR/${schema}_${tab}.dump"; mv "$TMP_DIR/${schema}_${tab}.dump" $DB_DIR/) &
  done

  wait
  # rm -rf $TMP_DIR
  # echo "    → Archiving $db"
  # tar -cf "$DB_DIR.tar" -C "$BASE_DIR" "pg-$db"
  # rm -rf "$DB_DIR"
done

wait
echo "[OK] PostgreSQL backup complete."

########################################
# 🔷 MariaDB Backup - Per Table, Size Filter #
########################################

echo "[INFO] Starting MariaDB backup..."

mysql -N -e "SHOW DATABASES;" | grep -Ev "^(mysql|information_schema|performance_schema|sys)$" | while read -r db; do
  echo "  → [$db]"
  DB_DIR="$BASE_DIR/my-$db"
  mkdir -p "$DB_DIR"

  mysql -N -e "
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = '$db'
      AND data_length + index_length < ${MAX_SIZE_MB} * 1024 * 1024;
  " | while read -r table; do
    echo "    → Dumping $table"
    mysqldump --single-transaction "$db" "$table" > "$DB_DIR/${table}.sql" &
  done

  wait
  # echo "    → Compressing $db"
  # tar -I zstd -cf "$DB_DIR.tar.zst" -C "$BASE_DIR" "my-$db"
  # rm -rf "$DB_DIR"
done

wait

echo "[OK] MariaDB backup complete."

########################################
# 🧹 Cleanup: Delete Backups Older Than 30 Days
########################################

echo "[INFO] Cleaning up old backups..."
find $SCRIPT_DIR -maxdepth 1 -type d -name '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -mtime +$RETENTION_DAYS -exec rm -rf {} \;
echo "[OK] Old backups cleaned."
