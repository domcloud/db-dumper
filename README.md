# DB-Dumper

A bash script to dump daily/weekly mariadb and postgresql database.

It's recommended to put this into other partition from the DB, such as in /home.

```sh
useradd -m -d /home/dumper -s /bin/bash dumper
git clone https://github.com/domcloud/db-dumper /home/dumper/db-dumper
bash /home/dumper/db-dumper/main.sh
```
