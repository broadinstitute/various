#!/bin/bash

#Defineables
#Threads non working right now
threads=8

#These shouldnt change
log_dir="/broad/stops/ecs-migration/logs"
s3cmd='/home/unix/daltschu/git/archive-cli/s3cmd/s3cmd -c /home/unix/daltschu/git/archive-cli/.s3cfg_osarchive'
project='broad-archive-legacy'
gsutil='/home/unix/daltschu/google-cloud-sdk/bin/gsutil'

#Location of boto file that contains credentials for ecs and google.
BOTOFILE=/broad/stops/ecs-migration/.boto_ecs

#Using this cloud sdk config folder DOESNT WORK. Just use the boto.
CONFIG_FOLDER=/broad/stops/ecs-migration/

eval export DK_ROOT="/broad/software/dotkit"; . /broad/software/dotkit/ksh/.dk_init
use -q Google-Cloud-SDK
use -q Python-2.7

#Ask yes or no, return 1 for yes, 0 for no
GetYN() {
        while true; do
                echo -n "[Y]es or [N]o? "
                read FINAL
                case $FINAL in
                        y | Y | yes | Yes) result=1; break ;;
                        n | N | no | No) result=0; break ;;
                esac
        done
}

S3_List(){
    num=0
    readarray -t dirs <<< "$( $s3cmd ls $1 | sed 's/.*s3:/s3:/' )"
    for dir in "${dirs[@]}" ; do
    	if [ $num -eq 0 ]; then
    		echo "0 - $dir"
                    num=$((num+1))
    	else
    		echo "$num - $dir"
    		num=$((num+1))
    	fi
    done
}

S3_List
printf '%s\n' "${dirs[@]}"
