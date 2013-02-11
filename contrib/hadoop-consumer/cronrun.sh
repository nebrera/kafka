#!/bin/bash
PROGRAM=`dirname $0`/hadoop-importer.sh
LOG_FACILITY="local1"

PATH=/bin:/usr/bin:/opt/hadoop/bin

exec 1> >(logger -i -p "${LOG_FACILITY}.info" -t "${PROGRAM}")
exec 2> >(logger -i -p "${LOG_FACILITY}.error" -t "${PROGRAM}")

echo Checking for existing job

hadoop job -list 2>/dev/null|grep `whoami`  

if [[ $? -ne 0 ]]; then
  echo Starting $PROGRAM
  $PROGRAM
else
  echo "Not starting import, still running"
fi

