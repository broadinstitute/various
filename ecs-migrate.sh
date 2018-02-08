#!/bin/bash

#Defineables
#Threads non working right now
threads=8

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

#Read in bucket listing to array
echo -e "\nPlease select a bucket by number:\n"
S3_List
echo ""

read -p "Which bucket:" num_sel

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

num2=0
if [ $result -eq 1 ]; then
	echo -e "Making bucket (Will be converted to lowercase if needed) ...."
	#CLOUDSDK_CONFIG=$CONFIG_FOLDER
	echo "BOTO_CONFIG=$BOTOFILE $gsutil -q mb -c coldline -p $project gs://broad-ecs-$bucket_clean"
else
	exit
fi

echo -e "\nHere are the files to upload: "

S3_List $bucket

read -p "Either type A for all files, or select a number to drill down into a subdir: " up_sel

if [ "$up_sel" == "A" ]; then
	echo "upload it all BABY!"
	for dir in "${dirs[@]}"; do
		#CLOUDSDK_CONFIG=$CONFIG_FOLDER
		sub_dir=$dir
         	sub_dir_clean="$( echo $sub_dir | tr "[:upper:]" "[:lower:]" | sed s'|s3://||' )"
		sub_dir_log_path="$( echo $sub_dir_clean | sed 's:/*$::' )"
		mkdir -p $log_dir/$sub_dir_clean
		#echo "BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $bucket_lower gs://broad-ecs-$bucket_clean &> $log_dir/$bucket_clean.log"i
		echo "BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $dir gs://broad-ecs-$sub_dir_clean $> $log_dir/$sub_dir_log_path.log"
	done
else
	sub_dir=${dirs[$up_sel]}
	echo "The list of files inside $sub_dir is:"
	S3_List $sub_dir
	echo "Would you like to upload these files?"
	result=0
	GetYN
	if [ $result=1 ]; then
		for dir in "${dirs[@]}" ; do
			sub_dir=$dir
			sub_dir_clean="$( echo $sub_dir | tr "[:upper:]" "[:lower:]" | sed s'|s3://||' )"
			sub_dir_log_path="$( echo $sub_dir_clean | sed 's:/*$::' )"
			mkdir -p $log_dir/$sub_dir_clean
			echo "BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $dir gs://broad-ecs-$sub_dir_clean $> $log_dir/$sub_dir_log_path.log"
		done
	else
		echo "gtfo then!"
		exit
	fi
			 
fi	





#	echo "Uploading ${dirs[$up_sel]}...."
#	dir_clean="$( echo ${bucks[$num_sel]} | tr "[:upper:]" "[:lower:]" | sed s'|s3://||' )"
#	#CLOUDSDK_CONFIG=$CONFIG_FOLDER
#	BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r ${dirs[$up_sel]} gs://broad-ecs-$dir_clean
#fi


#if [ $result -eq 1 ]; then
#	echo "CLOUDSDK_CONFIG=$CONFIG_FOLDER BOTO_CONFIG=$BOTOFILE $gsutil -m rsync -r $bucket gs://broad-ecs-$dir/"
#fi
