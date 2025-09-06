#!/bin/bash

# Optimized Clean Installation Script for Airflow-Airbyte Integration
# This script sets up all necessary directories, permissions, and starts the services
# with improved error handling and progress tracking

set -euo pipefail

echo "=============================================="
echo "Starting Optimized Clean Installation of Airflow-Airbyte Stack"
echo "=============================================="

# Ensure we're in the project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
handle_error() {
    local line_number="$1"
    local error_code="$2"
    log_error "Error occurred at line $line_number with exit code $error_code"
    exit "$error_code"
}

trap 'handle_error $LINENO $?' ERR

# Check if running as root (for Docker service management)
IS_ROOT=false
if [ "$EUID" -eq 0 ]; then
    IS_ROOT=true
fi

echo "----------------------------------------------"
log_info "Step 1: Setting up required directories"
echo "----------------------------------------------"

# Create all necessary directories with proper error handling
log_info "Creating project directories..."
mkdir -p temporal/dynamicconfig || { log_error "Failed to create temporal/dynamicconfig"; exit 1; }
mkdir -p plugins/dbt-athena || { log_error "Failed to create plugins/dbt-athena"; exit 1; }
mkdir -p sparkFiles || { log_error "Failed to create sparkFiles"; exit 1; }
mkdir -p logs || { log_error "Failed to create logs"; exit 1; }
mkdir -p outputs || { log_error "Failed to create outputs"; exit 1; }
mkdir -p dags || { log_error "Failed to create dags"; exit 1; }
mkdir -p config || { log_error "Failed to create config"; exit 1; }
mkdir -p plugins/python_extension/operators || { log_error "Failed to create plugins/python_extension/operators"; exit 1; }

# Create tmp directories for Airbyte
log_info "Creating tmp directories for Airbyte..."
mkdir -p /tmp/workspace /tmp/airbyte_local || { log_error "Failed to create tmp directories"; exit 1; }

# Create __init__.py file for Python extension
touch plugins/python_extension/__init__.py || { log_error "Failed to create __init__.py"; exit 1; }

echo "----------------------------------------------"
log_info "Step 2: Checking Docker environment"
echo "----------------------------------------------"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker before running this script."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_warn "Docker Compose not found. Installing..."
    if command -v pip3 &> /dev/null; then
        pip3 install --no-input docker-compose || { log_error "Failed to install docker-compose"; exit 1; }
    else
        log_error "pip3 not found. Please install pip3 to install docker-compose."
        exit 1
    fi
fi

# Enable and start Docker service (if running as root)
if [ "$IS_ROOT" = true ]; then
    log_info "Enabling and starting Docker service..."
    if command -v systemctl &> /dev/null; then
        systemctl enable docker.service 2>/dev/null || log_warn "Failed to enable Docker service"
        systemctl start docker.service 2>/dev/null || log_warn "Failed to start Docker service"
    else
        log_warn "systemctl not found. Skipping Docker service management."
    fi
else
    log_warn "Not running as root. Skipping Docker service management."
    log_warn "Please ensure Docker is running before proceeding."
fi

echo "----------------------------------------------"
log_info "Step 3: Setting up Python dependencies"
echo "----------------------------------------------"

# Install required Python packages
log_info "Installing required Python packages..."
if command -v pip3 &> /dev/null; then
    pip3 install --no-input cryptography || { log_error "Failed to install cryptography"; exit 1; }
else
    log_warn "pip3 not found. Skipping cryptography installation."
fi

echo "----------------------------------------------"
log_info "Step 4: Setting up environment variables"
echo "----------------------------------------------"

# Generate and add Fernet key to .env if it doesn't exist
if [ ! -f .env ]; then
    log_info "Creating .env file..."
    touch .env
fi

if ! grep -q "FERNET_KEY" .env; then
    log_info "Generating Fernet key..."
    if python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" &> /dev/null; then
        FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        echo "FERNET_KEY=$FERNET_KEY" >> .env
        log_info "Fernet key added to .env file"
    else
        log_warn "Failed to generate Fernet key. You may need to generate it manually."
    fi
else
    log_info "Fernet key already exists in .env file"
fi

echo "----------------------------------------------"
log_info "Step 5: Setting proper permissions"
echo "----------------------------------------------"

# Set permissions for directories and files
log_info "Setting permissions..."
chmod -R 777 dags/ logs/ plugins/ temporal/ sparkFiles/ outputs/ 2>/dev/null || log_warn "Failed to set permissions for some directories"
chmod 644 config/airflow.cfg 2>/dev/null || log_warn "Failed to set permissions for airflow.cfg"

# Set permissions for tmp directories (if running as root)
if [ "$IS_ROOT" = true ]; then
    chmod -R 777 /tmp/workspace /tmp/airbyte_local 2>/dev/null || log_warn "Failed to set permissions for tmp directories"
else
    log_warn "Not running as root. Skipping tmp directory permissions."
    log_warn "You may need to manually set permissions for /tmp/workspace and /tmp/airbyte_local"
fi

echo "----------------------------------------------"
log_info "Step 6: Building Docker images"
echo "----------------------------------------------"

# Build the Airflow image
log_info "Building Airflow Docker image..."
if docker build -f Dockerfile -t docker_airflow .; then
    log_info "Airflow Docker image built successfully"
else
    log_error "Failed to build Airflow Docker image"
    exit 1
fi

echo "----------------------------------------------"
log_info "Step 7: Stopping any existing services"
echo "----------------------------------------------"

# Stop any running services
log_info "Stopping existing services..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down 2>/dev/null || true
elif docker compose version &> /dev/null; then
    docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml down 2>/dev/null || true
else
    log_warn "Docker Compose not found. Skipping service shutdown."
fi

echo "----------------------------------------------"
log_info "Step 8: Pulling required Docker images"
echo "----------------------------------------------"

# Pull required images to speed up startup
log_info "Pulling Airbyte images..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.airbyte.yaml pull 2>/dev/null || log_warn "Failed to pull some Airbyte images"
elif docker compose version &> /dev/null; then
    docker compose -f docker-compose.airbyte.yaml pull 2>/dev/null || log_warn "Failed to pull some Airbyte images"
fi

echo "----------------------------------------------"
log_info "Step 9: Starting services"
echo "----------------------------------------------"

# Start the services
log_info "Starting Airflow and Airbyte services..."
if command -v docker-compose &> /dev/null; then
    if docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml up -d; then
        log_info "Services started successfully"
    else
        log_error "Failed to start services"
        exit 1
    fi
elif docker compose version &> /dev/null; then
    if docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml up -d; then
        log_info "Services started successfully"
    else
        log_error "Failed to start services"
        exit 1
    fi
else
    log_error "Docker Compose not found. Cannot start services."
    exit 1
fi

echo "----------------------------------------------"
log_info "Step 10: Verifying services"
echo "----------------------------------------------"

# Wait a moment for services to start
log_info "Waiting for services to initialize..."
sleep 15

# Check if services are running
log_info "Checking service status..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml ps
elif docker compose version &> /dev/null; then
    docker compose -f docker-compose.airflow.yaml -f docker-compose.airbyte.yaml ps
fi

echo "=============================================="
log_info "Installation Complete!"
echo "=============================================="
echo ""
log_info "Access Airflow at: http://localhost:8080"
log_info "Access Airbyte at: http://localhost:8000"
log_info "Access Flower at: http://localhost:5555"
echo ""
log_info "Default credentials:"
log_info "  Airflow: airflow / airflow"
log_info "  Airbyte: (check Airbyte documentation for defaults)"
echo ""
log_info "Next steps:"
log_info "1. Set up Airbyte connections in the web UI"
log_info "2. Run the auto_connection.sh script to configure the DAG"
log_info "3. Enable the DAG in the Airflow UI"