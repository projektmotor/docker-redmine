#!/bin/bash

/etc/init.d/ssh status

if [  "$?" != 0 ]; then
	/etc/init.d/ssh start
fi

/docker-entrypoint.sh $@
