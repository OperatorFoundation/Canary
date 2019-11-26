#!/bin/sh

echo "Rename Redis DBFilename*******"
redis-cli -p 6380 config set dbfilename "$1"
redis-cli -p 6380 shutdown save
