FROM openjdk:8

MAINTAINER Prashanth Babu <Prashanth.Babu@gmail.com>

# Scala related variables.
ARG SCALA_VERSION=2.11.8
ARG SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
ARG SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# SBT related variables.
ARG SBT_VERSION=1.1.2
ARG SBT_BINARY_ARCHIVE_NAME=sbt-$SBT_VERSION
ARG SBT_BINARY_DOWNLOAD_URL=https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/${SBT_BINARY_ARCHIVE_NAME}.tgz

# Spark related variables.
ARG SPARK_VERSION=2.3.0
ARG SPARK_BINARY_ARCHIVE_PREFIX=spark-${SPARK_VERSION}
ARG SPARK_BINARY_ARCHIVE_NAME=${SPARK_BINARY_ARCHIVE_PREFIX}-bin-hadoop2.7
ARG SPARK_BINARY_DOWNLOAD_URL=https://apache.org/dist/spark/${SPARK_BINARY_ARCHIVE_PREFIX}/${SPARK_BINARY_ARCHIVE_NAME}.tgz

# Configure env variables for Scala, SBT and Spark.
# Also configure PATH env variable to include binary folders of Java, Scala, SBT and Spark.
ENV SCALA_HOME  /usr/local/scala
ENV SBT_HOME    /usr/local/sbt
ENV SPARK_HOME  /usr/local/spark
ENV PATH        $JAVA_HOME/bin:$SCALA_HOME/bin:$SBT_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH

# Download, uncompress and move all the required packages and libraries to their corresponding directories in /usr/local/ folder.
RUN    echo 'deb http://security.debian.org/debian-security stretch/updates main' >>/etc/apt/sources.list && \
    apt-get -yqq update && \
    apt-get install -yqq vim screen tmux openssh-server && \
    apt-get clean && \
    /etc/init.d/ssh start && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${SBT_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/  && \
    cd /usr/local/ && \
    ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala && \
    ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties && \
    sed -i -e s/WARN/ERROR/g spark/conf/log4j.properties && \
    sed -i -e s/INFO/ERROR/g spark/conf/log4j.properties && \
    echo 'scalaVersion := "2.11.8"' > /root/build.sbt

RUN ssh-keygen -t RSA -f ~/.ssh/id_rsa -N '' && \
    mv ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys && \
    ssh-keyscan localhost > ~/.ssh/known_hosts && \
    /etc/init.d/ssh start && \
    /usr/local/spark-2.3.0-bin-hadoop2.7/sbin/start-all.sh


# We will be running our Spark jobs as `root` user.
USER root

# Working directory is set to the home folder of `root` user.
WORKDIR /root

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.
EXPOSE 4040 8080 8081 22

CMD ["/usr/local/spark/bin/spark-shell"]
