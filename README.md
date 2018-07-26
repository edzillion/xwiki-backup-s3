# xwiki-backup-s3

[xwiki-backup-s3] is a simple, automated, backup (and restore) [docker] container for [xwiki]. It supports xwiki configured with mysql (but postgres support would be trivial to add). 

By default it will create a backup of the xwiki folder and the database daily.

Inspired by [ghost-backup] and [docker-s3-volume] (thanks y'all!)

**Note:** default behaviour is only to backup (on a schedule and when the container is shut down). To enable restore, you need to set `BACKUP_ONLY=true`

> **Warning** `BACKUP_ONLY=false` will overwrite the current xwiki installation. This is so that we can automate server provisioning scripts to restore xwiki fully on boot.

### Quick Start

First create your s3 bucket. Take note of the region and add it to the `AWS_DEFAULT_REGION` environment variable. Turn on versioning and you can leave everything else on defaults.

> **Recommended** To limit the amount of backups you keep, (and $$$ to Lord Bezos) go to AWS s3 console and select your bucket. Click on _Management_ > _Add lifecycle rule_ > add rule name like 'File Expire Rule' > _Next_ > _Next_ (again) > Then edit settings as in image below

![add bucket lifecycle rule](https://raw.githubusercontent.com/edzillion/xwiki-backup-s3/master/readme_screenshot_1.png)

Create a network and a data volume to be shared by xwiki-backup-s3 and xwiki

`docker network create -d bridge xwiki-nw && docker volume create xwiki_data`

Run mysql and mount it on the data volume:

````
docker run -d --net=xwiki-nw --name mysql-xwiki -v xwiki_data:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=xwiki \ 
    -e MYSQL_USER=xwiki \
    -e MYSQL_PASSWORD=xwiki \ 
    -e MYSQL_DATABASE=xwiki \
    mysql:5.7 --character-set-server=utf8 --collation-server=utf8_bin --explicit-defaults-for-timestamp=1
````

Run xwiki on port 8080 and set it to use the xwiki_data volume:

````
docker run -d --net=xwiki-nw --name xwiki -p 8080:8080 -v xwiki_data:/usr/local/xwiki \
    -e DB_USER=xwiki 
    -e DB_PASSWORD=xwiki 
    -e DB_DATABASE=xwiki 
    -e DB_HOST=mysql-xwiki 
    xwiki:mysql-tomcat
````

Then run xwiki-backup-s3 and link it to the same volume, replacing `s3://your-bucket-here/folder` with your s3 bucket and `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` with your credentials (if you are running this on EC2, IAM roles will work and you do not need these env vars). 

````
docker run -d --name xwiki-backup-s3 --net=xwiki-nw -v xwiki_data:/data --link mysql \
    -e MYSQL_HOST=mysql-xwiki \
    -e MYSQL_USER=xwiki \
    -e MYSQL_PASSWORD=xwiki \
    -e MYSQL_DATABASE=xwiki \
    -e AWS_ACCESS_KEY_ID=<your aws key> \
    -e AWS_SECRET_ACCESS_KEY=<your aws secret> \
    edzillion/xwiki-backup-s3 s3://your-bucket-here/folder
````

That's it! This will create and run a container named 'xwiki-backup-s3' which will backup your files and db to s3 every day.

### Advanced Configuration
xwiki-backup-s3 has a number of options which can be configured as you need. 

| Environment Variable  | Default       | Meaning           |
| --------------------- | ------------- | ----------------- | 
| BACKUP_INTERVAL       | "1d"   | interval (s, m, h or d as the suffix)|
| AWS_DEFAULT_REGION       | "eu-central-1"    | **Note:** must be same as s3 bucket|
| BACKUP_ONLY  | true            | Will disable the initial restore|

For example, if you wanted to backup every 8 hours to the s3 bucket located in the `us-east-1` region called `us-east-1-bucket` and overwrite the current xwiki content:

````
docker run -d --name xwiki-backup-s3 --net=xwiki-nw -v xwiki_data:/data --link mysql \
    -e MYSQL_HOST=mysql-xwiki \
    -e MYSQL_USER=xwiki \
    -e MYSQL_PASSWORD=xwiki \
    -e MYSQL_DATABASE=xwiki \
    -e AWS_ACCESS_KEY_ID=<your aws key> \
    -e AWS_SECRET_ACCESS_KEY=<your aws secret> \
    -e BACKUP_INTERVAL=8h \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -e BACKUP_ONLY=false \
    edzillion/xwiki-backup-s3 s3://your-bucket-here/folder
````

### Other Info

When using mysql, the backup/restore is handled using mysqldump. You should use InnoDB tables for [online backup].

 [xwiki-backup-s3]: https://github.com/edzillion/xwiki-backup-s3
 [docker]: https://www.docker.com/
 [xwiki]: https://xwiki.org/
 [ghost-backup]: https://github.com/bennetimo/ghost-backup
 [docker-s3-volume]: https://github.com/elementar/docker-s3-volume
 [online backup]: https://dev.mysql.com/doc/refman/5.5/en/mysqldump.html