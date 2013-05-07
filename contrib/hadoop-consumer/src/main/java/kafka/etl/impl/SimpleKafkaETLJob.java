/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package kafka.etl.impl;

import kafka.etl.KafkaETLInputFormat;
import kafka.etl.KafkaETLJob;
import kafka.etl.Props;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.RunningJob;
import org.apache.hadoop.mapred.TextOutputFormat;

/**
 * This is a simple Kafka ETL job which pull text events generated by
 * DataGenerator and store them in hdfs
 */
@SuppressWarnings("deprecation")
public class SimpleKafkaETLJob {

    protected String _name;
    protected Props _props;
    protected String _input;
    protected String _output;
    protected String _topic;

  public SimpleKafkaETLJob(String name, Props props) throws Exception {
    _name = name;
    _props = props;

    _input = _props.getProperty("input");
    _output = _props.getProperty("output");

    _topic = props.getProperty("kafka.etl.topic");
  }


  protected JobConf createJobConf() throws Exception {
    JobConf jobConf = KafkaETLJob.createJobConf("SimpleKafakETL", _topic, _props, getClass());

    jobConf.setMapperClass(SimpleKafkaETLMapper.class);
    KafkaETLInputFormat.setInputPaths(jobConf, new Path(_input));

    jobConf.setOutputKeyClass(LongWritable.class);
    jobConf.setOutputValueClass(Text.class);
    jobConf.setOutputFormat(TextOutputFormat.class);
    TextOutputFormat.setCompressOutput(jobConf, false);
    Path output = new Path(_output);
    FileSystem fs = output.getFileSystem(jobConf);
    if (fs.exists(output)) fs.delete(output);
    TextOutputFormat.setOutputPath(jobConf, output);

    jobConf.set("mapred.compress.map.output", "true");
    jobConf.set("mapred.output.compression.type", "BLOCK");
    jobConf.set("mapred.map.output.compression.codec", "org.apache.hadoop.io.compress.GzipCodec");

    jobConf.setNumReduceTasks(0);
    return jobConf;
  }

    public void execute () throws Exception {
        JobConf conf = createJobConf();
        RunningJob runningJob = new JobClient(conf).submitJob(conf);
        String id = runningJob.getJobID();
        System.out.println("Hadoop job id=" + id);
        runningJob.waitForCompletion();

        if (!runningJob.isSuccessful()) 
            throw new Exception("Hadoop ETL job failed! Please check status on http://"
                                         + conf.get("mapred.job.tracker") + "/jobdetails.jsp?jobid=" + id);
    }

  /**
   * for testing only
   *
   * @param args
   * @throws Exception
   */
  public static void main(String[] args) throws Exception {

    if (args.length < 1)
      throw new Exception("Usage: - config_file");

    Props props = new Props(args[0]);
    SimpleKafkaETLJob job = new SimpleKafkaETLJob("SimpleKafkaETLJob",
        props);
    job.execute();
  }

}
