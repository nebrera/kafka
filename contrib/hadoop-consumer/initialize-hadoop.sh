#!/bin/bash

# Run in UTC
export TZ="/usr/share/zoneinfo/UTC"

#script uses relative paths, fixing it the old fashion way ;)
cd `dirname $0`

function usage() {
   echo "$0 [-t topic] [-d hdfs_dir] [-b list_of_brokers_file] [-g generated_property_file]"
}

while getopts "t:d:b:g:h" opt; do
  case $opt in
    t) topic=$OPTARG;;
    d) hdfs_dir=$OPTARG;;
    b) list_of_brokers=$OPTARG;;
    g) generated_property_file=$OPTARG;;
    h) usage;;
  esac
done

if [ -z "$topic" ]; then
   echo "ERROR: Must set $topic to kafka topic"
   exit 1
fi

if [ -z "$hdfs_dir" ]; then
   echo "ERROR: Must set $hdfs_dir to HDFS path"
   exit 1
fi

if [ -z "$list_of_brokers" ]; then
   echo "ERROR: Must set $list_of_brokers to a config file containing list of kafka servers"
   exit 1
fi

if [ -z "$generated_property_file" ]; then
   echo "ERROR: Must set $generated_property_file to filename we can use for storing state"
   exit 1
fi

if [ -z "$bucket_name" ]; then
   bucket_name=`date +%Y/%m/%d/%Hh%M/`
fi

current_offset_file_exists=`hadoop fs -ls ${hdfs_dir}/${bucket_name}/*.dat`

if [ -z "$current_offset_file_exists" ]; then
   echo "INFO: No offset file(s) found, so new one(s) will be generated for the topic '${topic}' starting from offset -1"

   if [ -f $list_of_brokers ]
   then
      printf "File \"$list_of_brokers\" was found\n"
      while read server
      do
         broker=${server}
         offset_file_name="offsets_000000m0-m-00000"
         hdfs_input=${hdfs_dir}/${bucket_name}
         eval "echo \"$(< template.properties)\"" > ${generated_property_file}
         ./run-class.sh kafka.etl.impl.DataGenerator ${generated_property_file}
         hadoop fs -mv ${hdfs_dir}/${bucket_name}/1.dat ${hdfs_dir}/${bucket_name}/${offset_file_name}.dat
      done < $list_of_brokers
   else
      printf "File \"$list_of_brokers\" was NOT found\n"
      exit 0
   fi
   hadoop fs -touchz  ${hdfs_dir}/${bucket_name}/_SUCCESS

else
   echo "INFO: Offset file(s) already found in ${hdfs_dir}/offset so no new one(s) will be created."
fi
