#!/bin/sh

master=$1

default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark/$master
drivers=$(etcdctl get etcd_spark/$master/drivers)
workers=$(etcdctl get etcd_spark/$master/workers)
driver_alias=$(etcdctl get etcd_spark/$master/driver_alias)
worker_alias=$(etcdctl get etcd_spark/$master/worker_alias)

for (( i=1 ; i<=drivers ; i++ ))
do
    driver="${driver_alias}-$i"
    curl -L -X DELETE $default_url/$driver/spark_env
    curl -L -X DELETE $default_url/$driver/to_publish
    curl -L -X DELETE $default_url/$driver/spark_defaults
done

for (( i=1 ; i<=workers ; i++ ))
do
    worker="${worker_alias}-$i"
    curl -L -X DELETE $default_url/$worker/spark_env
    curl -L -X DELETE $default_url/$worker/to_publish
    curl -L -X DELETE $default_url/$worker/DATANODE_PORT
    curl -L -X DELETE $default_url/$worker/WORKER_UI
    curl -L -X DELETE $default_url/$worker/WORKER_PORT
done

curl -L DELETE $default_url/spark_env
curl -L DELETE $default_url/to_publish
curl -L DELETE $default_url/name
curl -L DELETE $default_url/log4j
curl -L -X DELETE $default_url/workers
curl -L -X DELETE $default_url/drivers
curl -L -X DELETE $default_url/driver_alias
curl -L -X DELETE $default_url/worker_alias
