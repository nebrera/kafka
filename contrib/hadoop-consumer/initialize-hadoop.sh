#!/bin/bash

topic="madvertise"
hdfs_dir="/kafka"
list_of_brokers="servers.conf"
bucket_name=`date +%Y/%m/%d/%Hh%M/`
generated_property_file='current.properties'
current_offset_file_exists=`hadoop fs -ls ${hdfs_dir}/offset`

if [ -z "$current_offset_file_exists" ]; then
   echo "***************************************************************************************************************************"
   echo "No offset file(s) found, so new one(s) will be generated for the topic '${topic}' starting from offset -1"
   echo "***************************************************************************************************************************"

   if [ -f $list_of_brokers ]
   then
      printf "File \"$list_of_brokers\" was found\n"
      while read server
      do
         broker=${server}
         offset_file_name=`echo ${server} | sed -e 's/\:/-port/g'`
         eval "echo \"$(< template.properties)\"" > ${generated_property_file}
         ./run-class.sh kafka.etl.impl.DataGenerator ${generated_property_file}
         hadoop fs -mv ${hdfs_dir}/offset/1.dat ${hdfs_dir}/offset/${offset_file_name}.dat
      done < $list_of_brokers
   else
      printf "File \"$list_of_brokers\" was NOT found\n"
      exit 0
   fi

else
   echo "***************************************************************************************************************************"
   echo "Offset file(s) already found in ${hdfs_dir}/offset so no new one(s) will be created."
   echo "***************************************************************************************************************************"
fi