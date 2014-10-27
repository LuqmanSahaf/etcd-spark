# Spark
FROM spark-base:1.1.0
MAINTAINER luckysahaf lgsahaf@gmail.com

ENV SPARK_NODE_TYPE SUBMIT

ADD files /root/spark_submit_files

# Add the entrypoint script for the master
ENTRYPOINT ["/root/spark_submit_files/default_cmd"]
