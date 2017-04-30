#!/usr/bin/env bash

until [ "$up" == "y" ]; do
	cqlsh -e "exit" &> /dev/null
	[ $? -eq 0 ] && {
		up="y"
		break
	}
	sleep 0.5
done

[ -f /etc/cassandra/setup-done ] || {
	[ -f /etc/cassandra/schema.cdl ] && cqlsh -f /etc/cassandra/schema.cdl
	touch /etc/cassandra/setup-done
}

[ -z "$READY_PORT" ] && READY_PORT = "8080"

while true; do
	nc -l $READY_PORT
done
