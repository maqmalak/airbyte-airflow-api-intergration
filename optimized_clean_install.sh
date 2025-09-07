#!/bin/bash

# Clean installation script for Airflow-Airbyte integration
# This script sets up all necessary directories, permissions, and starts the services

echo "=============================================="
echo "Starting Clean Installation of Airflow-Airbyte Stack"
echo "=============================================="

# Ensure we're in the project directory
cd "$(dirname "$0")"

echo "----------------------------------------------"
echo "Step 1: Setting up required directories"
echo "----------------------------------------------"

# Create all necessary directories
echo "Creating project directories..."
mkdir -p temporal/dynamicconfig
mkdir -p plugins/dbt-athena
mkdir -p sparkFiles
mkdir -p dags
mkdir -p logs
mkdir -p plugins
mkdir -p outputs


# Create tmp directories for Airbyte (if they don't exist)
echo "Creating tmp directories for Airbyte..."
mkdir -p /tmp/workspace /tmp/airbyte_local

echo "----------------------------------------------"
echo "Step 2: Setting up Docker environment"
echo "----------------------------------------------"

# Enable and start Docker service (if running as root or with sudo privileges)
if [ "$EUID" -eq 0 ]; then
    echo "Enabling and starting Docker service..."
    systemctl enable docker.service
    systemctl start docker.service
else
    echo "NOTE: Not running as root. Checking if Docker is running..."
    if ! systemctl is-active --quiet docker; then
        echo "WARNING: Docker is not running. Please start Docker service with:"
        echo "sudo systemctl start docker"
        echo "Continuing installation assuming Docker will be started manually..."
    else
        echo "Docker is running."
    fi
fi

# Install required Python packages
echo "Installing required Python packages..."
pip3 install --no-input docker-compose
pip3 install --no-input cryptography

echo "----------------------------------------------"
echo "Step 3: Setting up environment variables"
echo "----------------------------------------------"

# # Generate and add Fernet key to .env if it doesn't exist
# if ! grep -q "FERNET_KEY" .env; then
#     echo "Generating Fernet key..."
#     echo -e "FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")" >> .env
# fi

echo "----------------------------------------------"
echo "Step 4: Setting proper permissions"
echo "----------------------------------------------"

# Set permissions for directories and files
echo "Setting permissions..."
chmod -R 777 dags/ logs/ plugins/ temporal/ sparkFiles/ outputs/ configs/

# Set permissions for config files if they exist
if [ -f "config/airflow.cfg" ]; then
    chmod 644 config/airflow.cfg
fi

if [ -f "requirements.txt" ]; then
    chmod 644 requirements.txt
fi

# Set permissions for tmp directories (if running as root or with sudo privileges)
if [ "$EUID" -eq 0 ]; then
    chmod -R 777 /tmp/workspace /tmp/airbyte_local
else
    echo "NOTE: Not running as root. Skipping tmp directory permissions."
    echo "You may need to manually set permissions for /tmp/workspace and /tmp/airbyte_local"
fi

echo "----------------------------------------------"
echo "Step 5: Building Docker images"
echo "----------------------------------------------"

# Build the Airflow image
echo "Building Airflow Docker image..."
docker build -f Dockerfile -t docker_airflow .

echo "----------------------------------------------"
echo "Step 6: Stopping any existing services"
echo "----------------------------------------------"

# Stop any running services
echo "Stopping existing services..."
docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down

echo "----------------------------------------------"
echo "Step 7: Starting services"
echo "----------------------------------------------"

# Start the services
echo "Starting Airflow and Airbyte services..."
docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml up -d

echo "----------------------------------------------"
echo "Step 8: Verifying services"
echo "----------------------------------------------"

# Wait a moment for services to start
sleep 10

# Check if services are running
echo "Checking service status..."
docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml ps

echo "=============================================="
echo "Installation Complete!"
echo "=============================================="
echo ""
echo "Access Airflow at: http://localhost:8080"
echo "Access Airbyte at: http://localhost:8000"
echo "Access Flower at: http://localhost:5555"
echo ""
echo "Default credentials:"
echo "  Airflow: airflow / airflow"
echo "  Airbyte: airbyte / 123"
echo ""
echo "Next steps:"
echo "1. Set up Airbyte connections in the web UI"
echo "2. Run the auto_connection.sh script to configure the DAG"
echo "3. Enable the DAG in the Airflow UI"