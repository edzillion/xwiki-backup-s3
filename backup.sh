#!/bin/bash

set -e

NOW=`date '+%Y%m%d-%H%M'`

echo "Removing and recreating /data/backup_files"
rm -rf /data/backup_files
mkdir -p /data/backup_files

# Backup the xwiki DB (either sqlite3 or mysql)
backupDB () {
  echo "creating xwiki db archive (mysql)..."
  #backup mysql
  echo "Backing up Mysql"
    
  # These environment variables should be available
  if [ -z "$MYSQL_HOST" ]; then echo "Error: MYSQL_HOST env var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_USER" ]; then echo "Error: MYSQL_USER entgzv var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_DATABASE" ]; then echo "Error: MYSQL_DATABASE env var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_PASSWORD" ]; then echo "Error: MYSQL_PASSWORD env var not set."; echo "Finished: FAILURE"; exit 1; fi
  mysqldump -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASSWORD --max_allowed_packet=512m --single-transaction --databases $MYSQL_DATABASE \
    | bzip2 > /data/backup_files/xwiki-backup-db.sql.bz2

  echo "...completed: /data/backup_files/xwiki-backup-db.sql.bz2"
}

# Backup the xwiki static files (images, themes, apps etc) but not the /data directory (the db backup handles that)
backupxwiki () {
  # echo "creating xwiki files archive..."
  #tar cfz "/data/backup_files/xwiki-backup-files.tar.gz" --directory='data' --exclude='data' --exclude='backup_files' . 2>&1 #Exclude the /data directory (we back that up separately)
  #echo "...completed: /data/backup_files/xwiki-backup-files.tar.gz"

  echo "Backing up Data"
  #Backup Exteral Data Storage
  /bin/tar -C /data/data/../ -zcf /data/backup_files/xwiki-backup-data.tar.gz data

  #Backing Java Keystore
  # /bin/cp /srv/tomcat6/.keystore ./backup_files/.keystore

  # echo "Backing up xwiki configuration"
  # /bin/cp /data/data/hibernate.cfg.xml /data/backup_files/hibernate.cfg.xml
  # /bin/cp /data/data/xwiki.cfg /data/backup_files/xwiki.cfg
  # /bin/cp /data/data/xwiki.properties /data/backup_files/xwiki.properties
}

backupxwiki
backupDB

echo "completed backup to /data/backup_files at: $NOW"