Compact Single-node Cassandra container with schema and triggers 

## Stack

Build from source of [Datax Cassandra](http://downloads.datastax.com/datastax-ddc) running on top of lightweight [Alphine Linux](https://alpinelinux.org).

## Usage

public image from dockerHub `docker pull jancajthaml/cassandra` optionally provide reference to schema.cdl file via volume configuration e.g. `./schema.cdl:/etc/cassandra/schema.cdl`

Docker exposes ready-and-up port (under env `READY_PORT`) after cassandra is up, gossip has finished and schema is ready

### Options
