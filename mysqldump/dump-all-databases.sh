#!/bin/bash
filename=all-databases.sql.gz
mysqluser=backupuser

mysqldump -u $mysqluser --all-databases | gzip -3 -c > $filename
