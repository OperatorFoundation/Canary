#!/bin/sh

echo "Shutdown Redis Server*******"
redis-cli -p 6380 shutdown
