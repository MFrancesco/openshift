FROM jboss/base-jdk:8

EXPOSE 9042 9160 7000 7001


ENV CASSANDRA_VERSION="3.11.4" \
    PATH="/opt/apache-cassandra/bin:$PATH"\
    CASSANDRA_SEEDS=""\
    CLUSTER_NAME=""\
    CASSANDRA_DC="dc1"\
    CASSANDRA_RACK="rack1"\
    AUTHORIZER="AllowAllAuthorizer"


USER root

RUN yum install -y -q bind-utils && \
   yum clean all

RUN cd /opt &&\
	curl -LO http://apache.uvigo.es/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz && ls -l &&\ 
    tar xvzf apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz && \
    rm apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz && \
    ln -s apache-cassandra-$CASSANDRA_VERSION apache-cassandra


#COPY cassandra-lucene-index-plugin-3.0.10.3.jar \
#     /opt/apache-cassandra/lib/

#COPY cassandra-lucene-index-plugin-3.10.0-RC1-SNAPSHOT.jar \
#     /opt/apache-cassandra/lib/     

COPY docker-entrypoint.sh \
     /opt/apache-cassandra/bin/

     
ADD cassandra.yaml.template /opt/apache-cassandra/conf/cassandra.yaml

RUN groupadd -r cassandra -g 312 && \
    useradd -u 313 -r -g cassandra -d /opt/apache-cassandra -s /sbin/nologin cassandra && \
    chown -R cassandra:cassandra /opt/apache-cassandra && \
    chmod -R go+rw /opt/apache-cassandra

RUN  mkdir -p /var/lib/cassandra/data && chmod +x /opt/apache-cassandra/bin/docker-entrypoint.sh

#Support Arbitrary User IDs with group root
RUN chgrp -R 0 /var/lib/cassandra && chmod -R g=u /var/lib/cassandra
RUN chgrp -R 0 /var/lib/cassandra/data && chmod -R g=u /var/lib/cassandra/data
RUN chgrp -R 0 /opt/apache-cassandra && chmod -R g=u /opt/apache-cassandra

VOLUME /var/lib/cassandra


