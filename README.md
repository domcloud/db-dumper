# DB-Dumper

A bash script to dump daily/weekly mariadb and postgresql database.

It's recommended to put this into other partition from the DB, such as in /home. The script should be run by `root`.

```sh
useradd -m -d /home/dumper -s /bin/bash dumper
git clone https://github.com/domcloud/db-dumper /home/dumper/db
bash /home/dumper/db/main.sh
```

## Configuration

You can put `.env` file here to customize the backup process.

| Key | Default | Description |
|:---|:---|:---|
| `TODAY` | Automatic | Today |
| `TMPDIR` | `/tmp/db-dumper` | PostgreSQL-accesible temporary directory to perform dump |
| `BASE_DIR` | `$SCRIPT_DIR/$TODAY` | The directory to perform dump |
| `MAX_SIZE_MB` | `512` | Maximum table size to perform dump |
| `RETENTION_DAYS` | `30` | Maximum days to retain old dumps |
| `RUN_PATCH` | `true` | Whether to run patch script to do incremental backup |
| `MYSQL_PASS` | Automatic (obtain from webmin) | MySQL root password |
