# Kafka Connect Avro Demo with Schema Registry and SMT

This repository provides an end-to-end demo of a Kafka Connect pipeline using Avro serialization, Confluent Schema Registry, and Single Message Transforms (SMTs). It moves data from a MySQL source table to a MySQL sink table via Kafka Connect with Avro converters.

---

## Features
- Custom Kafka Connect Docker image with JDBC connector and MySQL driver
- Confluent Platform stack (ZooKeeper, Kafka, Schema Registry, Connect)
- MySQL for source and sink databases
- Avro serialization with Schema Registry
- JDBC Source and Sink connector configurations
- Single Message Transforms (SMTs): RenameField and InsertField
- Sample SQL and curl commands for setup and verification

---

## Prerequisites
- Docker & Docker Compose installed 
- Git (to clone this repo)

---

##  Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/zeinab-dashti/kafka-connect-avro-demo.git
cd kafka-connect-avro-demo
```

### 2. Start the stack

```bash
docker-compose down -v  # Stop and remove containers and volumes
docker-compose up -d --build
```
All services (zookeeper, kafka, schema-registry, connect, mysql) start and stay Up.


### 3. Verify connector plugins availability
```bash
curl -s http://localhost:8083/connector-plugins | jq \
  '.[] | select(.class|test("Jdbc.*Connector"))'
```

### 4. Initialize the source table with a sample row

```bash
docker-compose exec mysql bash -lc "\
  mysql -uuser -ppassword mydb <<'EOF'
CREATE TABLE IF NOT EXISTS source_table (
  id INT PRIMARY KEY AUTO_INCREMENT,
  msg VARCHAR(255),
  ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO source_table (msg) VALUES ('Hello world');
EOF
"
```

### 5. Register connectors configurations and verify them

Register source connector
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/jdbc-source.json
```

Register sink connector
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/jdbc-sink.json
```

Check source connector status
```bash
curl -s http://localhost:8083/connectors/jdbc-source/status | jq .
```
Expected: "state":"RUNNING", tasks[0].state:"RUNNING"


Check sink connector status
```bash
curl -s http://localhost:8083/connectors/jdbc-sink/status | jq .
```
Expected: same RUNNING output

### 6. Smoke-test data flow with SMT

Insert a new row  into source_table:
```bash
docker-compose exec mysql mysql -uuser -ppassword mydb \
  -e "INSERT INTO source_table (msg) VALUES ('Goodbye world');"
```

Wait few seconds, then query sink_table
```bash
docker-compose exec mysql mysql -uuser -ppassword mydb \
  -e "SELECT * FROM sink_table ORDER BY id DESC LIMIT 3;"
```

Expected output: 
```
+----+---------------+-------------------------+-------------+
| id | msg           | ingest_ts               | source_name |
+----+---------------+-------------------------+-------------+
|  1 | Hello world   | 2025-05-25 18:33:47.000 | jdbc_source |
|  2 | Goodbye world | 2025-05-25 18:27:41.000 | jdbc_source |
+----+---------------+-------------------------+-------------+
```

This confirms the SMT pipeline successfully renamed ts to ingest_ts and added source_name to each record, with Avro serialization and Schema Registry integration.
