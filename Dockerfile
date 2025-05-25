FROM confluentinc/cp-kafka-connect:7.4.0

# 1) Install the JDBC plugin
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.6.1

# 2) Put the MySQL driver jar into the plugin's lib folder
RUN mkdir -p /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib && \
    curl -L -o /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/mysql-connector-java.jar \
      https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
