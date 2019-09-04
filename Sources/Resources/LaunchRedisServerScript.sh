#!/bin/sh

echo "*******Launch Redis Server"
echo `which redis-server`
echo "redis-server $1"

redis-server "$1"
