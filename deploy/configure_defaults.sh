#/bin/sh

drivers=$1
workers=$2
master=$3


declare -A config
cat defaults.conf | while read key value; do
    config[$key]=$value
done

rm -r $master
mkdir $master
cp spark-env.sh $master/
echo ${config["master.mem"]}
echo "export SPARK_MASTER_MEMORY=${config["master.mem"]}" >> $master/spark-env.sh

# For master
echo "name ${config["master.name"]}" > $master/config
echo "drivers $drivers" >> $master/config
echo "workers $workers" >> $master/config

# For drivers
for (( i=1 ; i<=$drivers ; i++ ))
do
    rm -r driver$1
    mkdir driver$1
    cp spark-env.sh driver$1/
    echo "export SPARK_EXECUTOR_MEMORY=${config["driver.executor_mem"]}" > driver$i/spark-env.sh
done

for (( i=1 ; i<=$workers ; i++ ))
do
    rm -r worker$1
    mkdir worker$1
    cp spark-env.sh worker$1/
    echo "export SPARK_WORKER_MEMORY=${config["worker.mem"]}" >> worker$i/spark-env.sh
    echo "export SPARK_WORKER_CORES=${config["worker.cores"]}" >> worker$i/spark-env.sh
done
