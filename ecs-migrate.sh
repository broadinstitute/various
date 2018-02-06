#!/bin/bash

threads=8
log="/broad/stops/ecs-migration/logs/$dir.log"
s3cmd="/git/archive-cli/s3cmd/s3cmd -c ~/git/archive-cli/.s3cfg_osarchive"
boto="BOTO_CONFIG=/broad/stops/tools/ecs/.boto_ecs"

dir=

eval export DK_ROOT="/broad/software/dotkit"; . /broad/software/dotkit/ksh/.dk_init 

#use UGER

use .python-2.7.9-sqlite3-rtrees

echo "$boto /home/unix/daltschu/google-cloud-sdk/bin/gsutil -m rsync -r s3://irods-archive/attic/$dir/ gs://broad-ecs-irods-archive/attic/$dir/"

