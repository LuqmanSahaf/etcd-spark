#/bin/sh

cat defaults.conf | {
    declare -A config
    while read key value; do
        config[$key]=$value
    done
    master_suffix=${config[master.suffix]}
    master=${config[master.alias]}$master_suffix
    drivers=${config[drivers]}
    workers=${config[workers]}
    rm -r $master
    mkdir $master
    cp spark-env.sh $master/
    echo export SPARK_MASTER_MEMORY=${config[master.mem]} >> $master/spark-env.sh
    driver_alias=${config[driver.alias]}
    worker_alias=${config[worker.alias]}

    # For master
    echo "name $master" > $master/config
    echo "drivers $drivers" >> $master/config
    echo "workers $workers" >> $master/config
    echo "driver.alias $driver_alias$master_suffix" >> $master/config
    echo "worker.alias $worker_alias$master_suffix" >> $master/config
    echo "master.suffix $master_suffix" >> $master/config

    default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark/$master

    curl -L $default_url/name -XPUT -d value=$master
    curl -L $default_url/spark_env -XPUT --data-urlencode value@master/spark-env.sh
    curl -L $default_url/log4j -XPUT --data-urlencode value@log4j.properties
    curl -L $default_url/drivers -XPUT -d value=$drivers
    curl -L $default_url/workers -XPUT -d value=$workers
    curl -L $default_url/driver_alias -XPUT -d value=$driver_alias
    curl -L $default_url/worker_alias -XPUT -d value=$worker_alias

    # For drivers
    for (( i=1 ; i<=$drivers ; i++ ))
    do
        driver="$driver_alias${master_suffix}-$i"
        rm -r $driver
        mkdir $driver
        cp spark-env.sh $driver/
        echo export SPARK_EXECUTOR_MEMORY=${config[driver.executor_mem]} >> $driver/spark-env.sh
        curl -L $default_url/driver$i/spark_env -XPUT --data-urlencode value@$driver/spark-env.sh
    done

    for (( j=1 ; j<=$workers ; j++ ))
    do
        worker="$worker_alias${master_suffix}-$j"
        rm -r $worker
        mkdir $worker
        cp spark-env.sh $worker/
        echo export SPARK_WORKER_MEMORY=${config[worker.mem]} >> $worker/spark-env.sh
        echo export SPARK_WORKER_CORES=${config[worker.cores]} >> $worker/spark-env.sh
        curl -L $default_url/$worker/spark_env -XPUT --data-urlencode value@$worker/spark-env.sh
    done
}
