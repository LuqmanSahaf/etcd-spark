#!/bin/sh

default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark

# load config file for master
declare -A master_config
cat master/config | {
    while read key value; do
        master_config[$key]=$value
    done

    drivers=${master_config["drivers"]}
    workers=${master_config["workers"]}
    master=${master_config["name"]}
    driver_alias=${master_config["driver.alias"]}
    worker_alias=${master_config["worker.alias"]}

    curl -L $default_url/$master/name -XPUT -d value=$master
    curl -L $default_url/$master/spark_env -XPUT --data-urlencode value@master/spark-env.sh
    curl -L $default_url/$master/log4j -XPUT --data-urlencode value@log4j.properties
    curl -L $default_url/$master/drivers -XPUT -d value=$drivers
    curl -L $default_url/$master/workers -XPUT -d value=$workers

    for (( i=1; i<=$drivers ; i++ ))
    do
        driver=$driver_alias$i
        curl -L $default_url/$master/$driver/spark_env -XPUT --data-urlencode value@driver$i/spark-env.sh
    done

    for (( i=1; i<=$workers ; i++ ))
    do
        worker=$driver_suffix$i
        curl -L $default_url/$master/$worker/spark_env -XPUT --data-urlencode value@worker$i/spark-env.sh
    done
}
