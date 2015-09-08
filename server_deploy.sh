#!/bin/bash
# Script for "deploying" the job server locally (meaning run assembly task from sbt build)
ENV=$1
if [ -z "$ENV" ]; then
  echo "Syntax: $0 <Environment>"
  echo "   for a list of environments, ls config/*.sh"
  exit 0
fi

bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR=`cd "$bin"/../config/; pwd`
fi
configFile="$CONFIG_DIR/$ENV.sh"
if [ ! -f "$configFile" ]; then
  echo "Could not find $configFile"
  exit 1
fi
. $configFile

majorRegex='([0-9]+\.[0-9]+)\.[0-9]+'
if [[ $SCALA_VERSION =~ $majorRegex ]]
then
  majorVersion="${BASH_REMATCH[1]}"
else
  echo "Please specify SCALA_VERSION in ${configFile}"
  exit 1
fi

echo Building Spark-Jobserver locally

cd $(dirname $0)/..
sbt ++$SCALA_VERSION job-server-extras/assembly
if [ "$?" != "0" ]; then
  echo "Assembly failed"
  exit 1
fi

FILES="job-server-extras/target/scala-$majorVersion/spark-job-server.jar
       bin/server_start.sh
       bin/server_stop.sh
       $CONFIG_DIR/$ENV.conf
	   $CONFIG_DIR/$ENV.sh
       config/log4j-server.properties"

echo Deploy locally -> Copy files

cp $FILES $SPARK_JOBSERVER_APP_HOME

mv $SPARK_JOBSERVER_APP_HOME/$ENV.sh $SPARK_JOBSERVER_APP_HOME/settings.sh