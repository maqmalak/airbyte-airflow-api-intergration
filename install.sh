#!/bin/bash

# Legacy installation script - use clean_install.sh for complete setup
echo "--------------------------------Setting Up EC2 Instance-----------------------"
sudo systemctl enable docker.service
sudo systemctl start docker.service
pip3 install --no-input docker-compose
pip3 install --no-input cryptography
echo -e "FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")" >>.env
echo "-----------------------------------Building Image-----------------------------"
mkdir -p temporal/dynamicconfig sparkFiles plugins/dbt-athena 


chmod -R 777 dags/ logs/ plugins/ temporal/ sparkFiles/ requirements.txt

echo "----------------------------------------------"
echo "NOTE: This script only sets up directories and permissions."
echo "Use './clean_install.sh' or 'make clean-install' for complete installation."
echo "----------------------------------------------"
