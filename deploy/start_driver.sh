#!/bin/sh

master=$1
driver=driver$2
private_ip=$3

driver_dir=$(pwd)/run/$driver

rm -r $driver_dir
mkdir -p $driver_dir

# get default configurations from etcd server
etcdctl get /etcd_spark/$master/$driver/spark_defaults > $driver_dir/spark-defaults.conf
to_publish=$(etcdctl get /etcd_spark/$master/$driver/to_publish)
etcdctl get /etcd_spark/$master/$driver/spark_env > $driver_dir/spark-env.sh
echo "export SPARK_LOCAL_IP=$private_ip" >> $driver_dir/spark-env.sh
etcdctl get /etcd_spark/$master/log4j > $driver_dir/log4j.properties


# First port in to_publish is driver UI port, so it should be published to 0.0.0.0
# Therefore $private_ip is not attached at the front. Other ports are published
# to private network.
count=0
publish_args=""
for i in ${to_publish[@]}
do
    if [ $count == 0 ] ; then
        count=$(( $count+1 ))
        publish_args="-p $i:$i"
    fi
    publish_args="$publish_args -p $private_ip:$i:$i"
done

env_args="-e ETCD_ADDRESS=$ETCD_IP -e ETCD_PORT=$ETCD_PORT -e HOST_ADDRESS=$private_ip"

# start docker container
docker run --name $driver -h $driver $publish_args $env_args -v $driver_dir:/home/run spark-shell:1.1.0 $master
