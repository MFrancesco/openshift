## Authentication on Strimzi


#### Configuring a cluster for authentication

1- Add in the cluster configuration files the configurations about authentication and authorization, adding a block like this 
```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: Kafka
metadata:
  name: fl-kafka-cluster-ephemeral-security
  namespace: test
spec:
...
    listeners:
      tls:
        authentication:
          type: scram-sha-512
      external:
        type: route
      plain: 
        authentication:
          type: scram-sha-512
    authorization:
      type: simple
...      
```
we are telling to use the scram-sha-512 autentication and simple authorization to our strimzi cluster named
*fl-kafka-cluster-ephemeral-security* under the *test* namespace.
After this step the *fl-kafka-cluster-ephemeral-security-cluster* will be created
Here's the full yaml file used to create the cluster
```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: Kafka
metadata:
  name: fl-kafka-cluster-ephemeral-security
  namespace: test
spec:
  entityOperator:
    topicOperator: {}
    userOperator: {}
  kafka:
    config:
      default.replication.factor: 1
      group.initial.rebalance.delay.ms: 2500
      log.message.format.version: "2.0"
      log.retention.hours: 24
      num.partitions: 11
      offsets.topic.replication.factor: 1
      transaction.state.log.min.isr: 1
      transaction.state.log.replication.factor: 1
    jvmOptions:
      -Xms: 512m
      gcLoggingEnabled: false
    listeners:
      tls:
        authentication:
          type: scram-sha-512
      external:
        type: route
      plain: 
        authentication:
          type: scram-sha-512
    authorization:
      type: simple          
    livenessProbe:
      initialDelaySeconds: 90
      timeoutSeconds: 5
    readinessProbe:
      initialDelaySeconds: 90
      timeoutSeconds: 5
    replicas: 1
    storage:
      type: ephemeral
    version: 2.0.0
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral

```


2- Use the [user operator](https://strimzi.io/docs/master/#assembly-user-operator-str) to generate a new user.
The user authorizations are handled by Access Control Lists configured in the file used to create the user itself. 
oc apply -f KafkaUser1.yml will create the user user1, here's the file
```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaUser
metadata:
  name: user1
  labels:
    strimzi.io/cluster: fl-kafka-cluster-ephemeral-security
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: "*"
          patternType: literal
        operation: All
      - resource:
          type: group
          name: "*"
          patternType: literal
        operation: All

```
Such user will have all permissions on all the groups and topics.
Once the user is created extract the password using the command `oc extract secret/user1` that will extract
the password that is Base64 encoded, to decode it use <password> | base64 --decode.
From now on i will refer to such password with value DECODED_PWD

3- Generate the keystore with the ca cert of the cluster
```bash
oc extract secret/fl-kafka-cluster-ephemeral-security-cluster-ca-cert --keys=ca.crt --to=- > ca.crt
keytool -import -trustcacerts -alias root -file ca.crt -keystore truststore.jks -storepass password -noprompt
```
This will generate the keystore truststore.jks with password password (of course you will change that)

4- Generate a property for both plaintext and ssl
security.properties
```properties
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
ssl.truststore.location=/tmp/truststore.jks
ssl.truststore.password=password
ssl.endpoint.identification.algorithm=
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODED_PWD;
```

security_plaintext.properties
```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODED_PWD;
```

#### Testing if the authorization is working

We have now all the elements to test if the authentication and authorization is working now.
To do so we will copy the properties files including the keystore under the /tmp folder 
of a kafka broker /tmp folder and the the server using the kafka-console-producer/consumer.sh scripts
under /opt/kafka/bin

After creating a test-topic we are ready to go
```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaTopic
metadata:
  name: test-topic
  labels:
    strimzi.io/cluster: fl-kafka-cluster-ephemeral-security
spec:
  partitions: 5
  replicas: 1
```

Let's try to write into the topic without authentications
```log
sh-4.2$ /opt/kafka/bin/kafka-console-producer.sh --broker-list fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 --topic test-topic
OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
>sss
[2019-06-14 16:32:49,357] WARN [Producer clientId=console-producer] Bootstrap broker fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 (id: -1 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2019-06-14 16:32:49,461] WARN [Producer clientId=console-producer] Bootstrap broker fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 (id: -1 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2019-06-14 16:32:49,564] WARN [Producer clientId=console-producer] Bootstrap broker fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 (id: -1 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
[2019-06-14 16:32:49,617] WARN [Producer clientId=console-producer] Bootstrap broker fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 (id: -1 rack: null) disconnected (org.apache.kafka.clients.NetworkClient)
```
Giving the authentication via producer.config option
```log
sh-4.2$ cat /tmp/security_plaintext.properties 
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODED_PWD;
   
sh-4.2$ /opt/kafka/bin/kafka-console-producer.sh --broker-list fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9092 --topic test-topic --producer.config /tmp/security_plaintext.properties
OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
>works 
>like
>a
>charm
``` 

Let's try with SSL on port 9093
```log
sh-4.2$ cat /tmp/security.properties 
security.protocol=SASL_SSL
ssl.truststore.location=/tmp/truststore.jks
ssl.truststore.password=password
ssl.endpoint.identification.algorithm=
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODED_PWD;
   
sh-4.2$ /opt/kafka/bin/kafka-console-producer.sh --broker-list fl-kafka-cluster-ephemeral-security-kafka-bootstrap:9093 --topic test-topic --producer.config /tmp/security.properties
OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
>works too
>
   
```

#### Bonus, configuring security on a spring-kafka application

Kafka configuration in spring is done using a [KafkaProperties](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/autoconfigure/kafka/KafkaProperties.html)
bean matching the properties in the application.yml file. 

Here's an example of configuration with SASL_PLAINTEXT protocol

```yaml
spring:
  kafka:
    streams:
      bootstrap-servers: "server-address:9092"#Tipically 9092 is for plaintext
      replication-factor: 1
      application-id: "app-id"
      group-id: "group-id"
    properties:
       security.protocol: "SASL_PLAINTEXT"
       sasl.mechanism: "SCRAM-SHA-512"
       sasl.jaas.config: "org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODEDPWD;"
```
Here's an example of configuration with SASL_SSL protocolo
```yaml
spring:
  kafka:
    streams:
      bootstrap-servers: "server-address:9093"#Tipically 9093 for SSL
      replication-factor: 1
      application-id: "app-id"
      group-id: "group-id"
    ssl:
       trust-store-location: file:///absolute/path/to/truststore.jks
       trust-store-password: truststorepwd
    properties:
      ssl.endpoint.identification.algorithm: ""
      security.protocol: "SASL_SSL"
      sasl.mechanism: "SCRAM-SHA-512"
      sasl.jaas.config: "org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=DECODEDPWD;"
```

