#!/bin/bash

/etc/init.d/ssh status

if [  "$?" != 0 ]; then
	/etc/init.d/ssh start
fi

/etc/init.d/ssh rsyslog

if [  "$?" != 0 ]; then
	/etc/init.d/rsyslog start
fi

/docker-entrypoint.sh $@
