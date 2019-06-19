### Remove a strimzi cluster

In order to fully clean your cluster the following steps has to be performed:

1- Remove the cluster via `oc remove Kafka clusterName`

2- Remove cluster users/topic via oc remove KafkaUser/KafkaTopic commands

3- Remove cluster serviceAccounts
