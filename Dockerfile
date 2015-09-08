FROM ubuntu:14.04.3
MAINTAINER tobilg <fb.tools.github@gmail.com>

# packages
RUN apt-get update && apt-get install -yq --no-install-recommends --force-yes \
    curl \
    wget \
    git \
	openjdk-6-jre \
	libjansi-java
	
#-headless

# Overall ENV vars
ENV SBT_VERSION=0.13.7
#ENV SCALA_VERSION=2.11.7
ENV SCALA_VERSION=2.10.5
ENV SPARK_VERSION=1.4.1
	
# sbt install
RUN wget https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
    dpkg -i sbt-$SBT_VERSION.deb && \
	rm sbt-0.13.7.deb

# scala install
RUN wget http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.deb && \
    dpkg -i scala-$SCALA_VERSION.deb && \
	rm scala-$SCALA_VERSION.deb

# Spark ENV vars
ENV SPARK_VERSION_STRING=spark-$SPARK_VERSION-bin-hadoop2.6
ENV SPARK_DOWNLOAD_URL=http://d3kbcqa49mib13.cloudfront.net/$SPARK_VERSION_STRING.tgz

# Download and unzip Spark
RUN wget $SPARK_DOWNLOAD_URL && \
    mkdir -p /usr/local/spark && \
    tar xvf $SPARK_VERSION_STRING.tgz -C /tmp && \
    cp -rf /tmp/$SPARK_VERSION_STRING/* /usr/local/spark/ && \
	rm -rf -- /tmp/$SPARK_VERSION_STRING && \
	rm spark-$SPARK_VERSION-bin-hadoop2.6.tgz

# Set SPARK_HOME
ENV SPARK_HOME=/usr/local/spark

# Download and unzip precompiled libmesos library (we do this because there is no installer for
# the most recent version of Mesos yet (0.24.0-rc1 as of 2015-09-07). Furthermore, this
# keeps the image smaller then installing Mesos itself. The libmesos library was compiled using
# the tobilg/mesos-master image, extracted and uploaded to Dropbox.
RUN wget https://www.dropbox.com/s/xfllam6ebcq15x9/libmesos-0.24.0-rc1.tar.gz?dl=0 && \
    mv ./libmesos-0.24.0-rc1.tar.gz?dl=0 ./libmesos-0.24.0-rc1.tar.gz && \
    tar xzf ./libmesos-0.24.0-rc1.tar.gz -C /usr/local/lib/ && \
	rm libmesos-0.24.0-rc1.tar.gz

# Set native Mesos library path
ENV MESOS_NATIVE_JAVA_LIBRARY=/usr/local/lib/libmesos-0.24.0-rc1.so

# H2 Database folder for Spark JobServer
RUN mkdir -p /database

# Clone Spark-Jobserver repository
ENV SPARK_JOBSERVER_BRANCH=v0.5.2
ENV SPARK_JOBSERVER_BUILD_HOME=/spark-jobserver
ENV SPARK_JOBSERVER_APP_HOME=/app
RUN git clone --branch $SPARK_JOBSERVER_BRANCH https://github.com/spark-jobserver/spark-jobserver.git
RUN mkdir -p $SPARK_JOBSERVER_APP_HOME

# Add custom files, set permissions
ADD docker.conf $SPARK_JOBSERVER_BUILD_HOME/config/docker.conf
ADD docker.sh $SPARK_JOBSERVER_BUILD_HOME/config/docker.sh
ADD log4j-docker.properties $SPARK_JOBSERVER_BUILD_HOME/config/log4j-server.properties
ADD server_deploy.sh $SPARK_JOBSERVER_BUILD_HOME/bin/server_deploy.sh
RUN chmod +x $SPARK_JOBSERVER_BUILD_HOME/bin/server_deploy.sh
RUN chmod +x $SPARK_JOBSERVER_BUILD_HOME/bin/server_start.sh
RUN chmod +x $SPARK_JOBSERVER_BUILD_HOME/bin/server_stop.sh

# Build Spark-Jobserver
WORKDIR $SPARK_JOBSERVER_BUILD_HOME
RUN bin/server_deploy.sh docker && \
    rm -rf -- $SPARK_JOBSERVER_BUILD_HOME

# Cleanup files, folders and variables
RUN unset SPARK_VERSION_STRING && \
    unset SPARK_DOWNLOAD_URL && \
	unset SPARK_JOBSERVER_BRANCH && \
	unset SPARK_JOBSERVER_BUILD_HOME

EXPOSE 8090 9999

ENTRYPOINT ["/app/server_start.sh"]