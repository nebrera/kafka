#!/bin/bash

topic="madvertise"
hdfs_dir="/kafka"
bucket_name=`date +%Y/%m/%d/%Hh%M/`
generated_property_file='current.properties'
current_offset_file_exists=`hadoop fs -ls ${hdfs_dir}/offset`

eval "echo \"$(< template.properties)\"" > ${generated_property_file}

if [ -z "$current_offset_file_exists" ]; then
   echo "***************************************************************************************************************************"
   echo "WARNING: Offset file(s) not found. The hadoop job cannot be run."
   echo "To generate the initial offset files, please run the following command:"
   echo "./initalize-hadoop.sh"
   echo "***************************************************************************************************************************"
else

   echo "***************************************************************************************************************************"
   echo "Importing topic '${topic}' to HDFS directory: ${hdfs_dir}/${bucket_name}"
   echo "***************************************************************************************************************************"

   ./run-class.sh kafka.etl.impl.SimpleKafkaETLJob ${generated_property_file}

   hadoop_consumer_successful=`hadoop fs -ls ${hdfs_dir}/${bucket_name}_SUCCESS`

   if [ -z "$hadoop_consumer_successful" ]; then
      echo "***************************************************************************************************************************"
      echo "ERROR: The hadoop job does not report a success."
      echo "The original offset file(s) used for the input of this job have been left untouched, so that you can retry later."
      echo "***************************************************************************************************************************"
   else
      echo "***************************************************************************************************************************"
      echo "SUCCESS: The hadoop job reports that it is successful."
      echo "The original offset file(s) used for the input of this job will now be deleted and replaced by those outputted by this job."
      echo "***************************************************************************************************************************"

      hadoop fs -rm ${hdfs_dir}/offset/*

      old_offset_files_still_exist=`hadoop fs -ls ${hdfs_dir}/offset`

      if [ -z "$old_offset_files_still_exist" ]; then
         echo "***************************************************************************************************************************"
         echo "SUCCESS: The original offset file(s) used for the input of this job have been deleted from the offset directory in HDFS."
         echo "***************************************************************************************************************************"

         hadoop fs -mv ${hdfs_dir}/${bucket_name}offsets* ${hdfs_dir}/offset/

         new_offset_files_present_in_offset_dir=`hadoop fs -ls ${hdfs_dir}/offset`

         if [ -z "$new_offset_files_present_in_offset_dir" ]; then
            echo "***************************************************************************************************************************"
            echo "ERROR: The new offset file(s) were not successfully moved to the offset directory."
            echo "***************************************************************************************************************************"
         else
            echo "***************************************************************************************************************************"
            echo "SUCCESS: The new offset file(s) have been moved to the offset directory."
            echo "***************************************************************************************************************************"
         fi
      else
         echo "***************************************************************************************************************************"
         echo "ERROR: The original offset file(s) used for the input of this job could NOT be deleted from the offset directory."
         echo "***************************************************************************************************************************"
      fi
   fi
fi
