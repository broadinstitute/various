#!/bin/bash

threads=8
log="/broad/stops/ecs-migration/logs/$dir.log"
s3cmd='/home/unix/daltschu/git/archive-cli/s3cmd/s3cmd -c /home/unix/daltschu/git/archive-cli/.s3cfg_osarchive'
project='broad-archive-legacy'


bucket=


#BULLSHIT I CANT GET WORKING
#export BOTO_CONFIG=/broad/stops/ecs-migration/.boto_ecs
#export BOTO_CONFIG=/home/unix/daltschu/.boto_ecs
#boto='BOTO_CONFIG=/broad/stops/ecs-migration/.boto_ecs'

eval export DK_ROOT="/broad/software/dotkit"; . /broad/software/dotkit/ksh/.dk_init 
#use UGER
#use .python-2.7.9-sqlite3-rtrees

readarray -t dirs <<< "$( $s3cmd ls | cut -d ' ' -f 4)"

echo -e "\nPlease select a bucket by number:\n"

echo ""

num=1

for dir in "${dirs[@]:1}" ; do
	echo "$num - $dir"
	num=$((num+1))
done

echo ""

read -p "Which bucket:" num_sel

until [ "$num_sel" -le "${#dirs[@]}" ]
do
	if [ "$num_sel" -gt "${#dirs[@]}" ]; then
		echo -e "not a valid bucket!\n"
		read -p "Which bucket:" num_sel
	fi
done

echo -e "You chose ${dirs[$num_sel]} \n"






#echo "BOTO_CONFIG=/broad/stops/ecs-migration/.boto_ecs' /home/unix/daltschu/google-cloud-sdk/bin/gsutil -m rsync -r s3://irods-archive/attic/$dir/ gs://broad-ecs-irods-archive/attic/$dir/"

