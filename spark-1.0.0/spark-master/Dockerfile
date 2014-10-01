# Spark
FROM spark-base:1.0.0
MAINTAINER amplab amp-docker@eecs.berkeley.edu

ENV SPARK_NODE_TYPE "MASTER"

# Expose TCP ports 7077 8080
EXPOSE 7077 8080

ADD files /root/spark_master_files

CMD ["/root/spark_master_files/default_cmd"]
