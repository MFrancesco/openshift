### Cassandra cluster on Openshift

I love cassandra and i used it in a couple of projects deployed in [openshift](https://www.openshift.com/)

Since [by default, OS containers are not allowed to use a root user](https://blog.openshift.com/getting-any-docker-image-running-in-your-own-openshift-cluster/) and i was unable to find a suitable public docker image i ended up writing my own cassandra docker and then, my own template to deploy a cassandra cluster via stateful set 

This docker folder contains the source used to compile the docker pushed on [this dockerhub repo](https://cloud.docker.com/u/frehub/repository/docker/frehub/cassandra)


#### Prerequisite

Running openshift cluster with available storage class, able to download images from dockerhub

#### How to use

1- Import the [cassandra templace](cassandra_stateful_template.json)

2- Tune the configuration as needed

3- Enjoy


#### Compatibility

Tested in both Openshift origin 3.9 and Okd 3.11 