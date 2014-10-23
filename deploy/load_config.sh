#!/bin/sh

default_url=http:$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark

# load config file for master
drivers=0
workers=0
declare -A master_config

cat master/config | while read key value; do
    master_config[$key]=$value
done

drivers=${master_config["drivers"]}
workers=${master_config["workers"]}

curl -L $default_url/${master_config["name"]}/name -XPUT -d value=${master_config["name"]}
curl -L $default_url/${master_config["name"]}/spark_env -XPUT --data-urlencode value@master/spark-env.sh
curl -L $default_url/${master_config["name"]}/log4j -XPUT --data-urlencode value@master/log4j.properties

for (( i=1; i<=$drivers ; i++ ))
do
    curl -L $default_url/${master_config["name"]}/driver$i/spark_env -XPUT --data-urlencode value@driver$i/spark-env.sh
done

for (( i=1; i<=$workers ; i++ ))
do
    curl -L $default_url/${master_config["name"]}/worker$i/spark_env -XPUT --data-urlencode value@worker$i/spark-env.sh
done
