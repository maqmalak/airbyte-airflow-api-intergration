## Build instructions & commands

# build the airflow image
build-airflow-image:
	docker build -f Dockerfile -t docker_airflow .

# start airflow and airbyte localy
start-airflow-airbyte-stack: 
	docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml up

# uninstall airflow and airbyte localy
uninstall-airflow-airbyte-stack: 
	docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down

# restart airflow and airbyte locally
restart-airflow-airbyte-stack:
	docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down && docker-compose -f docker-compose.airflow.yaml	-f docker-compose.airbyte.yaml up

# purge everything then setup again
purge-then-clean-install:
	docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down && docker system prune -a && docker build -f Dockerfile -t docker_airflow . && docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml up

## Airbyte credentials
#BASIC_AUTH_USERNAME=airbyte
#BASIC_AUTH_PASSWORD=password

## Airflow credentials
#BASIC_AUTH_USERNAME=airflow
#BASIC_AUTH_PASSWORD=airflow

## Ports
#airbyte is on port 8000
#airflow is on port 8080
#Flower is on port 5555