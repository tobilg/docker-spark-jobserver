# Docker environment vars
# NOTE: only static vars not intended to be changed by users should appear here, because
#       this file gets sourced in the middle of server_start.sh, so it will override
#       any env vars set in the docker run command line.

# Security settings
APP_USER=spark
APP_GROUP=spark

# Installation settings
INSTALL_DIR=$SPARK_JOBSERVER_APP_HOME

# Run settings
LOG_DIR=/var/log/job-server
PIDFILE=spark-jobserver.pid
JOBSERVER_MEMORY=1G

# Spark version settings
SPARK_CONF_DIR=$SPARK_HOME/conf

# For Docker, always run start script as foreground
JOBSERVER_FG=1