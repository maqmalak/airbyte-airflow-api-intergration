#!/bin/bash
echo "Access Airbyte at http://localhost:8000 and set up a connection Then copy the connection id from the connection page url."
echo "Enter your Airbyte connection ID: "
read connection_id
echo "---------Setting connection ID for DAG job---------"
# Set connection ID for DAG.
docker-compose -f docker-compose.airflow.yaml run airflow-webserver airflow variables set 'AIRBYTE_CONNECTION_ID' "$connection_id"
docker-compose -f docker-compose.airflow.yaml run airflow-webserver airflow connections add 'airbyte_example' --conn-uri 'airbyte://airbyte-server:8001'
