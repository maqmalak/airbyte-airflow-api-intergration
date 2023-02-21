#!/bin/bash
echo "--------------------------------Setting Up EC2 Instance-----------------------"
sudo systemctl enable docker.service
sudo systemctl start docker.service
pip3 install --no-input docker-compose
pip3 install --no-input cryptography
echo -e "FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")" >>.env
echo "-----------------------------------Building Image-----------------------------"
chmod -R 777 dags/ logs/ plugins/ requirements.txt
