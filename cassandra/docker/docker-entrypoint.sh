#!/bin/bash

echo "Cassandra seed value: $CASSANDRA_SEEDS"
echo "Authorizer value: $AUTHORIZER"
echo ""

sed -i 's/${SEEDS_PLACEHOLDER}/'$CASSANDRA_SEEDS'/g' /opt/apache-cassandra/conf/cassandra.yaml

if [ ! -z "$CASSANDRA_SEEDS" ]; then
    export CASSANDRA_SEEDS
fi


mkdir -p /var/lib/cassandra/data
mkdir -p /var/lib/cassandra/commitlog
mkdir -p /var/lib/cassandra/saved_caches


# set the hostname in the cassandra configuration file
sed -i 's/${HOSTNAME}/'$HOSTNAME'/g' /opt/apache-cassandra/conf/cassandra.yaml

# set the cluster name if set, default to "test_cluster" if not set
if [ -n "$CLUSTER_NAME" ]; then
    sed -i 's/${CLUSTER_NAME_PLACEHOLDER}/'$CLUSTER_NAME'/g' /opt/apache-cassandra/conf/cassandra.yaml
else
    echo "No CLUSTER_NAME env value, setting cluster name to test_cluster"
    sed -i 's/${CLUSTER_NAME_PLACEHOLDER}/test_cluster/g' /opt/apache-cassandra/conf/cassandra.yaml
fi
# set the authorizer, default to AllowAllAuthorizer
if [ -n "$AUTHORIZER" ]; then
    sed -i 's/${AUTHORIZER_PLACEHOLDER}/'$AUTHORIZER'/g' /opt/apache-cassandra/conf/cassandra.yaml
else
    echo "No AUTHORIZER env value, setting authorizer to AllowAllAuthorizer"
    sed -i 's/${AUTHORIZER_PLACEHOLDER}/AllowAllAuthorizer/g' /opt/apache-cassandra/conf/cassandra.yaml
fi
# set the cassandra datacenter value
if [ -n "$CASSANDRA_DC" ]; then
    sed -i 's/dc=dc1/dc='$CASSANDRA_DC'/g' /opt/apache-cassandra/conf/cassandra-rackdc.properties
fi
# set the rack value
if [ -n "$CASSANDRA_RACK" ]; then
    sed -i 's/rack=rack1/rack='$CASSANDRA_RACK'/g' /opt/apache-cassandra/conf/cassandra-rackdc.properties
fi
cat /opt/apache-cassandra/conf/cassandra.yaml

exec /opt/apache-cassandra/bin/cassandra -f -R