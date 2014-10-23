#!/bin/sh
. ${SPARK_HOME}/conf/spark-env.sh
${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker --webui-port $SPARK_WORKER_UI_PORT $MASTER
