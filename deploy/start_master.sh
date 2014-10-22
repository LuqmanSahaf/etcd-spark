#!/bin/sh

master=$1
private_ip=$2
master_mem=$3

master_dir=/home/$master

rm -r $master_dir
mkdir -p $master_dir

etcdctl set /etcd_spark/$master/name $master
spark_env=$(etcdctl get /etcd_spark/$master/spark_env)
log4j=$(etcdctl get /etcd_spark/$master/log4j)

echo $log4j > $master_dir/log4j.properties
echo $spark_env > $master_dir/spark-env.sh

publish_args="-p 8080:8080 -p $private_ip:7077:7077 -p $private_ip:9000:9000"
env_args="-e ETCD_ADDRESS=$ETCD_IP -e ETCD_PORT=$ETCD_PORT -e HOST_ADDRESS=$private_ip"

# start docker container
docker run --name $master -h $master $publish_args $env_args -v $master_dir:/home/run luckysahaf/spark-master:1.1.0
