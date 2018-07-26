#!/bin/bash

set -e

# Restore the database from the given archive file
restoreDB () {
  RESTORE_FILE=$1

  # mysql/mariadb
  echo "restoring data from mysql dump file: $RESTORE_FILE"
  # These environment variables should be available
  if [ -z "$MYSQL_HOST" ]; then echo "Error: MYSQL_HOST env var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_USER" ]; then echo "Error: MYSQL_USER env var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_DATABASE" ]; then echo "Error: MYSQL_DATABASE env var not set."; echo "Finished: FAILURE"; exit 1; fi
  if [ -z "$MYSQL_PASSWORD" ]; then echo "Error: MYSQL_PASSWORD env var not set."; echo "Finished: FAILURE"; exit 1; fi
  
  bunzip2 < $RESTORE_FILE | mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD 
  #cd data
  #tar -zxvf $RESTORE_FILE > db.sql

  # mysql -h $MYSQL_HOST -u $MYSQL_USER -p $MYSQL_PASSWORD < db.sql
  # mysql -u $MYSQL_USER -p $MYSQL_PASSWORD -h $MYSQL_HOST  db.sql || MYSQL_DATABASEexit 1
  echo "...restored xwiki DB archive $RESTORE_FILE"
  
  echo "db restore complete"
}

# Restore the xwiki files (themes etc) from the given archive file
restorexwiki () {
  RESTORE_FILE=$1

  # echo "removing xwiki files in /data"
  # rm -r data/apps/ data/images/ data/logs/ data/themes/ #Do not remove /data
  echo "restoring xwiki files from archive file: $RESTORE_FILE"
  tar -xzf $RESTORE_FILE --directory='data' 2>&1

  echo "file restore complete"
}

# Attempt to restore xwiki and db files
FILES_ARCHIVE="/data/backup_files/xwiki-backup-data.tar.gz"
DB_ARCHIVE="/data/backup_files/xwiki-backup-db.sql.bz2"

if [[ ! -f $FILES_ARCHIVE ]]; then
    echo "The xwiki archive file $FILES_ARCHIVE does not exist. Aborting."
    exit 1
fi
if [[ ! -f $DB_ARCHIVE ]]; then
    echo "The xwiki db archive file $DB_ARCHIVE does not exist. Aborting."
    exit 1
fi

echo "Restoring xwiki files and db"
restorexwiki $FILES_ARCHIVE
restoreDB $DB_ARCHIVE

echo "Removing  /data/backup_files"
rm -rf /data/backup_files