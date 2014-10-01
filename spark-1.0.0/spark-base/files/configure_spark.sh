#!/bin/bash

source /root/hadoop_files/configure_hadoop.sh

function create_spark_directories() {
    create_hadoop_directories
    rm -rf /opt/spark-$SPARK_VERSION/work
    mkdir -p /opt/spark-$SPARK_VERSION/work
    chown hdfs.hdfs /opt/spark-$SPARK_VERSION/work
    mkdir /tmp/spark
    chown hdfs.hdfs /tmp/spark
    # this one is for Spark shell logging
    rm -rf /var/lib/hadoop/hdfs
    mkdir -p /var/lib/hadoop/hdfs
    chown hdfs.hdfs /var/lib/hadoop/hdfs
    rm -rf /opt/spark-$SPARK_VERSION/logs
    mkdir -p /opt/spark-$SPARK_VERSION/logs
    chown hdfs.hdfs /opt/spark-$SPARK_VERSION/logs
}

function deploy_spark_files() {
    deploy_hadoop_files
    cp /root/spark_files/spark-env.sh /opt/spark-$SPARK_VERSION/conf/
    cp /root/spark_files/log4j.properties /opt/spark-$SPARK_VERSION/conf/
}		

function configure_spark() {
    configure_hadoop $1
    #sed -i s/__MASTER__/$1/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
    #CHANGE STARTS HERE#
    # added some logic for adding capability of specifying IP through argument.
    # The argument may be given through command line or fetched through etcd.
    # LOGIC::
	# If the user does not provide the IP of master, then check what the node
	# type is. If it's MASTER, then use hostname as master, else if it's WORKER
	# then use the default  name "master"! Else use the provided IP as the master ip.
    if [$1 == ""]; then
	if [ $SPARK_NODE_TYPE == "MASTER"]; then
            sed -i s/__MASTER__/$(hostname)/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
        else
            sed -i s/__MASTER__/master/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
        fi
    else
        sed -i s/__MASTER__/$1/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
    fi    

    #sed -i s/__MASTER__/master/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
    #CHANGE ENDS HERE#
    sed -i s/__SPARK_HOME__/"\/opt\/spark-${SPARK_VERSION}"/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
    sed -i s/__JAVA_HOME__/"\/usr\/lib\/jvm\/java-7-openjdk-amd64"/ /opt/spark-$SPARK_VERSION/conf/spark-env.sh
}

function prepare_spark() {
    create_spark_directories
    deploy_spark_files
    configure_spark $1
}
