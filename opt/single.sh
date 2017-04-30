#!/usr/bin/env bash

IP=${LISTEN_ADDRESS:-$(hostname)}
SEEDS=${SEEDS:-$IP}

[ $# == 1 ] && SEEDS="$1,$SEEDS"

[[ $(env | grep _PORT_9042_TCP_ADDR) ]] && SEEDS="$SEEDS,$(env | grep _PORT_9042_TCP_ADDR | sed 's/.*_PORT_9042_TCP_ADDR=//g' | sed -e :a -e N -e 's/\n/,/' -e ta)"

sed -i -e "
s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/;
s/^rpc_address.*/rpc_address: 0.0.0.0/;
s/# broadcast_address.*/broadcast_address: $IP/;
s/LOCAL_JMX=yes/LOCAL_JMX=no/;
s/# broadcast_rpc_address.*/broadcast_rpc_address: $IP/;
s/num_tokens/\#num_tokens/;
s/^start_rpc.*$/start_rpc: false/;
s/^start_native_transport.*$/start_native_transport: true/;
s/^commitlog_segment_size_in_mb.*/commitlog_segment_size_in_mb: 64/;
s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG/cassandra.yaml

sed -ri 's/^(JVM_PATCH_VERSION)=.*/\1=25/' $CASSANDRA_CONFIG/cassandra-env.sh
echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.initial_token=0\"" >> $CASSANDRA_CONFIG/cassandra-env.sh
echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.skip_wait_for_gossip_to_settle=0\"" >> $CASSANDRA_CONFIG/cassandra-env.sh

cassandra-setup & exec cassandra -R -f
