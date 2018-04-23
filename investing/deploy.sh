#!/bin/bash

export PORT=5302
export MIX_ENV=prod
export GIT_PATH=/home/investing/src/investing

PWD=`pwd`
if [ $PWD != $GIT_PATH ]; then
	echo "Error: Must check out git repo to $GIT_PATH"
	echo "  Current directory is $PWD"
	exit 1
fi

if [ $USER != "investing" ]; then
	echo "Error: must run as user 'investing'"
	echo "  Current user is $USER"
	exit 2
fi

mix deps.get
(cd assets && npm install)
(cd assets && ./node_modules/brunch/bin/brunch b -p)
mix phx.digest
mix ecto.create
mix ecto.migrate

mix release --env=prod

mkdir -p ~/www
mkdir -p ~/old

NOW=`date +%s`
if [ -d ~/www/investing ]; then
	echo mv ~/www/investing ~/old/$NOW
	mv ~/www/investing ~/old/$NOW
fi

mkdir -p ~/www/investing
REL_TAR=~/src/investing/_build/prod/rel/investing/releases/0.0.1/investing.tar.gz
(cd ~/www/investing && tar xzvf $REL_TAR)

crontab - <<CRONTAB
@reboot bash /home/investing/src/investing/start.sh
CRONTAB

#. start.sh
