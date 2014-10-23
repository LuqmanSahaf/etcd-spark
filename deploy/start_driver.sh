#!/bin/sh

master=$1
driver=$2
private_ip=$3

driver_dir=/home/driver

rm -r $driver_dir
mkdir $driver_dir

# get default configurations from etcd server
spark_defaults=$(etcdctl get /etcd_spark/$master/$driver/spark_defaults)
to_publish=$(etcdctl get /etcd_spark/$master/$driver/to_publish)
spark_env=$(etcdctl get /etcd_spark/$master/$driver/spark_env)
log4j=$(etcdctl get /etcd_spark/$master/log4j)

# saving into files
echo $log4j > $driver_dir/log4j.properties
echo $spark_env > $driver_dir/spark-env.sh
echo $spark_defaults > $driver_dir/spark-defaults.conf

# First port in to_publish is driver UI port, so it should be published to 0.0.0.0
# Therefore $private_ip is not attached at the front. Other ports are published
# to private network.
count=0
publish_args=""
for i in ${to_publish[@]}
do
    if [ count == 0 ] ; then
        count=$(( count+1 ))
        publish_args="$publish_args -p $i:$i"
    fi
    publish_args="$publish_args -p $private_ip:$i:$i"
done

env_args="-e ETCD_ADDRESS=$ETCD_IP -e ETCD_PORT=$ETCD_PORT -e HOST_ADDRESS=$private_ip"

# start docker container
docker run --name $driver -h $driver $publish_args $env_args -v $driver_dir:/home/run spark-shell:1.1.0 $master
