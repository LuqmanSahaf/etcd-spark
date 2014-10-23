#!/bin/sh

default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark

drivers=0
workers=0

# load config file for master
declare -A master_config
cat master/config | {
    while read key value; do
        master_config[$key]=$value
    done

    drivers=${master_config["drivers"]}
    workers=${master_config["workers"]}
    master=${master_config["name"]}
    curl -L $default_url/$master/name -XPUT -d value=$master
    curl -L $default_url/$master/spark_env -XPUT --data-urlencode value@master/spark-env.sh
    curl -L $default_url/$master/log4j -XPUT --data-urlencode value@log4j.properties
    curl -L $default_url/$master/drivers -XPUT -d value=$drivers
    curl -L $default_url/$master/workers -XPUT -d value=$workers

    for (( i=1; i<=$drivers ; i++ ))
    do
        curl -L $default_url/$master/driver$i/spark_env -XPUT --data-urlencode value@driver$i/spark-env.sh
    done

    for (( i=1; i<=$workers ; i++ ))
    do
        curl -L $default_url/$master/worker$i/spark_env -XPUT --data-urlencode value@worker$i/spark-env.sh
    done
}
