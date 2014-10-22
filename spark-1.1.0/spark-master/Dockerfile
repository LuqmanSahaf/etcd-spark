# Spark
FROM spark-base:1.1.0
MAINTAINER luckysahaf lgsahaf@gmail.com

ENV SPARK_NODE_TYPE MASTER

# Expose TCP ports 7077 8080
EXPOSE 7077 8080

ADD files /root/spark_master_files

ENTRYPOINT ["/root/spark_master_files/default_cmd"]
