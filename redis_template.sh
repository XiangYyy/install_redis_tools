#!/bin/bash

INSTALL_PATH={{ INSTALL_PATH }}
IP={{ BIND_IP }}
PORT={{ PORT }}
PASSWORD="{{ REDIS_PASSWORD }}"

CONFIGFILE=$INSTALL_PATH/etc/${PORT}.conf
EXEC=$INSTALL_PATH/bin/redis-server
CLIEXEC=$INSTALL_PATH/bin/redis-cli
PIDFILE=$INSTALL_PATH/log/redis_${PORT}.pid

case "$1" in
start)
    if [ -f "$PIDFILE" ]; then
        echo "$PIDFILE exists, process is already running or crashed"
    else
        echo "Starting Redis server..."
        $EXEC "$CONFIGFILE"
    fi
    ;;
stop)
    if [ ! -f "$PIDFILE" ]; then
        echo "$PIDFILE does not exist, process is not running"
    else
        PID=$(cat "$PIDFILE")
        echo "Stopping ..."
        if [ "$PASSWORD" == "" ]; then
            $CLIEXEC -h "$IP" -p "$PORT" shutdown
        else
            $CLIEXEC -h "$IP" -p "$PORT" -a "$PASSWORD" shutdown
        fi

        while [ -x "/proc/${PID}" ]; do
            echo "Waiting for Redis to shutdown ..."
            sleep 1
        done
        echo "Redis stopped"
    fi
    ;;
status)
    if [ ! -e "$PIDFILE" ]; then
        echo "pid file:$PIDFILE not exist!!"
        echo "redis is not running"
        ps -ef | grep "redis" | grep -w "$IP" | grep -w "$PORT" | grep -v grep
        exit 1
    fi
    PID=$(cat "$PIDFILE")
    if [ ! -x "/proc/${PID}" ]; then
        echo 'Redis is not running'
    else
        echo "Redis is running ($PID)"
    fi
    ;;
restart)
    $0 stop
    $0 start
    ;;
*)
    echo "Please use start, stop, restart or status as first argument"
    ;;
esac
