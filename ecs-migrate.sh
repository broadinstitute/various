#!/bin/bash

threads=8
log="/broad/stops/ecs-migration/logs/$dir.log"
s3cmd='/home/unix/daltschu/git/archive-cli/s3cmd/s3cmd -c /home/unix/daltschu/git/archive-cli/.s3cfg_osarchive'
project='broad-archive-legacy'
gsutil='/home/unix/daltschu/google-cloud-sdk/bin/gsutil'


BOTOFILE=/broad/stops/ecs-migration/.boto_ecs
CONFIG_FOLDER=/broad/stops/ecs-migration/
eval export DK_ROOT="/broad/software/dotkit"; . /broad/software/dotkit/ksh/.dk_init 
#use UGER
#use .python-2.7.9-sqlite3-rtrees
use -q Google-Cloud-SDK
use -q Python-2.7


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

readarray -t bucks <<< "$( $s3cmd ls | sed 's/.*s3:/s3:/' )"

echo -e "\nPlease select a bucket by number:\n"

num=0

for buck in "${bucks[@]}" ; do
	if [ $num -eq 0 ]; then
		echo "0 - $buck"
		num=$((num+1))
	else
		echo "$num - $buck"
		num=$((num+1))
	fi
done

echo ""

read -p "Which bucket:" num_sel

until [ "$num_sel" -le "${#bucks[@]}" ]
do
	if [ "$num_sel" -gt "${#bucks[@]}" ]; then
		echo -e "not a valid bucket!\n"
		read -p "Which bucket:" num_sel
	fi
done

bucket=${bucks[$num_sel]}
bucket_clean="$( echo $bucket | tr "[:upper:]" "[:lower:]" | sed s'|s3://||' )"

echo -e "\nYou chose $bucket \n"

echo -e "Would you like to make a google bucket and then drill down?"
GetYN
#yes is a 1 - no is a 0

num2=0
if [ $result -eq 1 ]; then
	echo -e "Making bucket (Will be converted to lowercase if needed) ...."
	CLOUDSDK_CONFIG=$CONFIG_FOLDER BOTO_CONFIG=$BOTOFILE $gsutil -q mb -c coldline -p $project gs://$bucket_clean
else
	exit
fi

echo -e "\n Here are the files to upload: "

readarray -t dirs <<< "$( $s3cmd ls $bucket | sed 's/.*s3:/s3:/' )"
for dir in "${dirs[@]}" ; do
	if [ $num2 -eq 0 ]; then
		echo "0 - $dir"
                num2=$((num2+1))
	else
		echo "$num2 - $dir"
		num2=$((num2+1))
	fi
done

read -p "Either type A for all files, or select a number to upload individually: " up_sel

if [ "$up_sel" == "A" ]; then 
	echo "upload it all!"
fi


#if [ $result -eq 1 ]; then
#	echo "CLOUDSDK_CONFIG=$CONFIG_FOLDER BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $bucket gs://broad-ecs-$dir/"
#fi

