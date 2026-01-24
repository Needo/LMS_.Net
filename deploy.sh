#!/bin/bash

# LMS Docker Deployment Script for Ubuntu
# This script automates the deployment of the LMS application using Docker

set -e

echo "=========================================="
echo "LMS Application Docker Deployment"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list again
    sudo apt-get update
    
    # Install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully!"
    echo "⚠️  Please log out and log back in for group changes to take effect."
    echo "Then run this script again."
    exit 0
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Installing Docker Compose..."
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose installed successfully!"
fi

echo ""
echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if we're in the LMSSystem directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found!"
    echo "Please run this script from the LMSSystem directory."
    exit 1
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Remove old images (optional)
read -p "Do you want to remove old images and rebuild? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing old images..."
    docker-compose down --rmi all 2>/dev/null || true
fi

# Create Courses directory if it doesn't exist
if [ ! -d "Courses" ]; then
    echo "📁 Creating Courses directory..."
    mkdir -p Courses
    echo "⚠️  Please add your course files to the 'Courses' directory"
fi

# Build and start containers
echo ""
echo "🏗️  Building Docker images (this may take several minutes)..."
docker-compose build

echo ""
echo "🚀 Starting containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if containers are running
if [ "$(docker-compose ps -q | wc -l)" -eq 2 ]; then
    echo ""
    echo "=========================================="
    echo "✅ LMS Application deployed successfully!"
    echo "=========================================="
    echo ""
    echo "📋 Service Information:"
    echo "  - LMS Application: http://localhost:5000"
    echo "  - SQL Server: localhost:1433"
    echo ""
    echo "👤 Default Users:"
    echo "  Admin:   admin@lms.com / password123"
    echo "  Student: student@lms.com / password123"
    echo ""
    echo "📁 Course Files Directory: ./Courses"
    echo ""
    echo "📊 View logs: docker-compose logs -f"
    echo "🛑 Stop services: docker-compose down"
    echo "🔄 Restart services: docker-compose restart"
    echo ""
else
    echo ""
    echo "❌ Error: Some containers failed to start"
    echo "Check logs with: docker-compose logs"
    exit 1
fi

# Show container status
echo "Container Status:"
docker-compose ps

echo ""
echo "🎉 Deployment complete! Access the application at http://localhost:5000"
