madvertise stable master [kafka](https://github.com/apache/kafka)
=================================================================

This repo is always the latest stable snapshot of [kafka](https://github.com/apache/kafka) with the following delta

- [X] [hadoop-consumer](https://github.com/madvertise/kafka/tree/master/contrib/hadoop-consumer) modified to work with [druid](https://github.com/madvertise/druid).


hadoop-consumer
---------------

We include a set of scripts:

- [copy-jars.sh](https://github.com/madvertise/kafka/blob/master/contrib/hadoop-consumer/copy-jars.sh) - run once to copy jars to HDFS
- [initialize-hadoop.sh](https://github.com/madvertise/kafka/blob/master/contrib/hadoop-consumer/initialize-hadoop.sh) - run once to init cursors
- [hadoop-importer.sh](https://github.com/madvertise/kafka/blob/master/contrib/hadoop-consumer/hadoop-importer.sh) - run as often as wanted

These scripts configured by environment variables:

```
export topic="your topic"
export hdfs_dir="/target/path/in/hdfs"
export generated_property_file="tmp_file_for_this_topic"
export list_of_brokers="config_file_containing_servers"
```

This can be added with command line options:
initialize-hadoop.sh -t <topic> -d <hdfs_dir> -b <list_of_brokers> -g <generated_property_file>


Example file for `$list_of_brokers`:

```
kafka1.example.com:9092
kafka2.example.com:9092
```

Make sure to end the file with a '\n' or the last server is ignored

Credit
------

Based on [Kafka DISTRIBUTED incremental Hadoop consumer](http://felixgv.com/post/88/kafka-distributed-incremental-hadoop-consumer/)
