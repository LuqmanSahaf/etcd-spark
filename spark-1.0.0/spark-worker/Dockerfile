# Spark
FROM spark-base:1.0.0
MAINTAINER LuqmanSahaf lgsahaf@gmail.com

ENV SPARK_NODE_TYPE WORKER

# Instead of using a random port, bind the worker to a specific port
ENV SPARK_WORKER_PORT 8888
EXPOSE 8888

ADD files /root/spark_worker_files

# Add the entrypoint script for the master
CMD ["-h"]
ENTRYPOINT ["/root/spark_worker_files/default_cmd"]
