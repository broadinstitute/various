#!/bin/bash

#Defineables
#Threads non working right now
threads=8
multithread=''

#These shouldnt change
log_dir="/broad/stops/ecs-migration/logs"
s3cmd='/home/unix/daltschu/git/archive-cli/s3cmd/s3cmd -c /home/unix/daltschu/git/archive-cli/.s3cfg_osarchive'
project='broad-archive-legacy'
gsutil='/home/unix/daltschu/google-cloud-sdk/bin/gsutil'
bucket=

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

#Lists directories in an s3 path
S3_List(){
    num=0
    readarray -t dirs <<< "$( $s3cmd ls $1 | sed 's/.*s3:/s3:/' )"
    for dir in "${dirs[@]}" ; do
    	if [ $num -eq 0 ]; then
    		echo "0 - $dir"
                    num=$((num+1))
    	else	
		#Fix some weird listing bug
    		if [[ $dir == $1 ]]; then 
			unset dirs[$num]
		else 
			echo "$num - $dir"
    			num=$((num+1))
    		fi
	fi
    done
}

#loops directories in the array returned from S3_List, then uploads each one.
Upload(){
    for dir in "${dirs[@]}"; do
        #CLOUDSDK_CONFIG=$CONFIG_FOLDER
        sub_dir=$dir
        sub_dir_clean="$( echo $sub_dir | tr "[:upper:]" "[:lower:]" | sed s'|s3://||' )"
        mkdir -p $log_dir/$sub_dir_clean
        #echo "BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $bucket_lower gs://broad-ecs-$bucket_clean &> $log_dir/$bucket_clean.log"
	echo "Running sync of $dir to gs://broad-ecs-$sub_dir_clean"
        BOTO_CONFIG=$BOTOFILE $gsutil $multithread rsync -r $dir gs://broad-ecs-$sub_dir_clean &> $log_dir/$sub_dir_clean/upload.log &
    done
}

#Displays top level buckets
echo -e "\nPlease select a bucket by number:\n"
S3_List
echo ""

#Asks user to pick bucket
read -p "Which bucket:" num_sel

#Pick an in bound number
until [ "$num_sel" -le "${#dirs[@]}" ]
do
	if [ "$num_sel" -gt "${#dirs[@]}" ]; then
		echo -e "not a valid bucket!\n"
		read -p "Which bucket:" num_sel
	fi
done

bucket="$( echo ${dirs[$num_sel]} )"
bucket_lower="$( echo $bucket | tr "[:upper:]" "[:lower:]" )"
bucket_clean="$( echo $bucket_lower | sed s'|s3://||' )"

echo -e "\nYou chose $bucket \n"

echo -e "Would you like to make a google bucket (if one doesnt exist) and then drill down?"
GetYN

#Makes a bucket in gsutil with the same name as in ECS but lowercase
num2=0
if [ $result -eq 1 ]; then
	echo -e "Making bucket (Will be converted to lowercase) ...."
	#CLOUDSDK_CONFIG=$CONFIG_FOLDER
	BOTO_CONFIG=$BOTOFILE $gsutil -q mb -c coldline -p $project gs://broad-ecs-$bucket_clean
else
	exit
fi

#List the files inside the bucket you selected
echo -e "\nHere are the files to upload: "
S3_List $bucket

read -p "Either type A for all files, or select a number to drill down into a subdir: " up_sel

if [ "$up_sel" == "A" ]; then
	#Loops through the directories in the first level of the bucket and uploads each
	echo "Uploading all files..."
	Upload $dirs
else
	sub_dir=${dirs[$up_sel]}
	echo "The list of files inside $sub_dir is:"
	S3_List $sub_dir
	echo "Would you like to upload these files?"
	result=0
	GetYN
	if [ $result -eq 1 ]; then
		#Drill down one level and do the same as above
		Upload $dirs
	elif [ $result -eq 0 ]; then
		echo "exiting"
		exit
	fi

fi
