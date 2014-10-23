#!/bin/bash

declare -A master_config
cat master/config | {
    while read key value; do
        master_config[$key]=$value
    done
    master=${master_config["name"]}
    drivers=${master_config["drivers"]}
    workers=${master_config["workers"]}

    default_url=http://$ETCD_IP:$ETCD_PORT/v2/keys/etcd_spark/$master

    #generate a random port between 12345 and 65535
    PORT=$(( ( RANDOM % 53190 )  + 12345 ))

    # Master ports:
    # UI. master_port, hadoop_namenode
    master_ui=$PORT
    master_port=$(( $PORT + 1 ))
    namenode=$(( $PORT + 2 ))

    PORT=$(( $PORT + 3 ))

    # Driver ports:
    # driver, broadcast, replClassServer, fileserver, UI
    for (( i=1; i<=$drivers ; i++ ))
    do
        driverUI[$i]=$PORT
        driver_port[$i]=$(( $PORT + 1 ))
        broadcast[$i]=$(( $PORT + 2 ))
        replClassServer[$i]=$(( $PORT + 3 ))
        fileserver[$i]=$(( $PORT + 4 ))
        blockManager[$i]=$(( $PORT + 5 ))
        executor[$i]=$(( $PORT + 6 ))
        echo "spark.driver.host driver$i" > driver$i/spark-defaults.conf
        echo "spark.driver.port ${driver_port[$i]}" >> driver$i/spark-defaults.conf
        echo "spark.replClassServer.port  ${replClassServer[$i]}" >> driver$i/spark-defaults.conf
        echo "spark.fileserver.port  ${fileserver[$i]}" >> driver$i/spark-defaults.conf
        echo "spark.ui.port  ${driverUI[$i]}" >> driver$i/spark-defaults.conf
        echo "spark.blockManager.port  ${blockManager[$i]}" >> driver$i/spark-defaults.conf
        echo "spark.executor.port  ${executor[$i]}" >> driver$i/spark-defaults.conf

        # create new file and add to to_publish ports
        to_publish="${driverUI[$i]} ${driver_port[$i]} ${broadcast[$i]} ${replClassServer[$i]} ${fileserver[$i]}"

        # Put the files in etcd server
        curl -L -XPUT "${default_url}/driver${i}/spark_defaults" --data-urlencode value@driver${i}/spark-defaults.conf
        curl -L -XPUT "${default_url}/driver${i}/to_publish" -d value=\"${to_publish}\"

        PORT=$(( $PORT +  ($i + 1) * 7 ))
    done

    #Worker ports:
    # worker, blockManager, executor, datanode (hadoop) ,UI
    for (( j=1; j<=$workers ; j++ ))
    do
        workerUI[$j]=$PORT
        worker[$j]=$(( $PORT + 1 ))
        datanode[$j]=$(( $PORT + 2 ))
        to_publish="${workerUI[$j]} ${worker[$j]} ${datanode[$j]} "

        for (( k=1; k<=$drivers ; k++ ))
        do
            to_publish="$to_publish ${executor[$k]} ${blockManager[$k]}"
        done

        curl -L -XPUT "$default_url/worker$j/to_publish" --data-urlencode -d value=\"${to_publish}\"
        curl -L -XPUT "$default_url/worker$j/WORKER_UI" --data-urlencode -d value=${workerUI[$j]}
        curl -L -XPUT "$default_url/worker$j/WORKER_PORT" --data-urlencode -d value=${worker[$j]}
        curl -L -XPUT "$default_url/worker$j/DATANODE_PORT" -d value=\"${datanode[$j]}\"

        PORT=$(( $PORT +  ($j + 1) * 3 ))
    done
}
