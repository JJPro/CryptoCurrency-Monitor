#!/bin/bash

export PORT=5302

cd ~/www/investing
./bin/investing stop || true
./bin/investing start
