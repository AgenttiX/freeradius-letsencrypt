#!/usr/bin/env sh
set -e

sudo apt-get update
sudo apt-get install freeradius

freeradius -C -X
