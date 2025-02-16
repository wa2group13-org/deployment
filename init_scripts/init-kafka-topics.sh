#!/bin/sh

KT="/opt/bitnami/kafka/bin/kafka-topics.sh"

echo "Waiting for kafka..."
"$KT" --bootstrap-server localhost:9092 --list

echo "Creating kafka topics"
"$KT" --bootstrap-server localhost:9092 --create --if-not-exists --topic topic-crm-message --replication-factor 1 --partitions 1
# Configure with 10MB of maximux message
"$KT" --bootstrap-server localhost:9092 --create --if-not-exists --topic topic-document-store-message --replication-factor 1 --partitions 1 --config max.message.bytes=10485760

echo "Successfully created the following topics:"
"$KT" --bootstrap-server localhost:9092 --list
