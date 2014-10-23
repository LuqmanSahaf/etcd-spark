#/bin/sh

drivers=$1
workers=$2

cat defaults.conf | {
    declare -A config
    while read key value; do
        config[$key]=$value
    done
    master=${config[master.name]}
    rm -r $master
    mkdir $master
    cp spark-env.sh $master/
    echo export SPARK_MASTER_MEMORY=${config[master.mem]} >> $master/spark-env.sh

    # For master
    echo "name ${config["master.name"]}" > $master/config
    echo "drivers $drivers" >> $master/config
    echo "workers $workers" >> $master/config

    # For drivers
    for (( i=1 ; i<=$drivers ; i++ ))
    do
        rm -r driver$i
        mkdir driver$i
        cp spark-env.sh driver$i/
        echo export SPARK_EXECUTOR_MEMORY=${config[driver.executor_mem]} >> driver$i/spark-env.sh
    done

    for (( j=1 ; j<=$workers ; j++ ))
    do
        rm -r worker$j
        mkdir worker$j
        cp spark-env.sh worker$j/
        echo export SPARK_WORKER_MEMORY=${config[worker.mem]} >> worker$j/spark-env.sh
        echo export SPARK_WORKER_CORES=${config[worker.cores]} >> worker$j/spark-env.sh
    done
}
