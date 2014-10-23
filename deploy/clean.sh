#!/bin/sh

master=$1

# Keys to remove from etcd:
# master/name
# worker*/spark_env
# worker*/WORKER_UI
# worker*/WORKER_PORT
# worker*/to_publish
# driver*/spark_defaults
# driver*/spark_env
# driver*/to_publish

default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark/$master
drivers=$(etcdctl get etcd_spark/$master/drivers)
workers=$(etcdctl get etcd_spark/$master/workers)

for (( i=1 ; i<=drivers ; i++ ))
do
    curl -L -X DELETE $default_url/driver$i/spark_env
    curl -L -X DELETE $default_url/driver$i/to_publish
    curl -L -X DELETE $default_url/driver$i/spark_defaults
done

for (( i=1 ; i<=workers ; i++ ))
do
    curl -L -X DELETE $default_url/worker$i/spark_env
    curl -L -X DELETE $default_url/worker$i/to_publish
    curl -L -X DELETE $default_url/worker$i/DATANODE_PORT
    curl -L -X DELETE $default_url/worker$i/WORKER_UI
    curl -L -X DELETE $default_url/worker$i/WORKER_PORT
done

curl -L DELETE $default_url/spark_env
curl -L DELETE $default_url/to_publish
curl -L DELETE $default_url/name
curl -L DELETE $default_url/log4j
curl -L -X DELETE $default_url/workers
curl -L -X DELETE $default_url/drivers
