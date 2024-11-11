#!/bin/bash

# Prompt for views folder location, Redis password, and main project folder
read -p "Enter the path to the 'views' folder: " views_path
read -s -p "Enter the password you want to set for Redis: " redis_password
echo
read -p "Enter the path to the main project folder: " project_folder

# Update System
echo "Updating system packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install ubuntu-restricted-extras -y

# Install essential libraries
echo "Installing essential libraries..."
sudo apt install unzip zip nginx -y
sudo apt-get install libatk1.0-0 libnss3 libxss1 libasound2 libatk-bridge2.0-0 libgtk-3-0 -y

# Install missing library for MongoDB
echo "Installing missing MongoDB dependencies..."
wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "Adding MongoDB repository..."
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update -y
sudo apt-get install -y mongodb-org

# Start MongoDB
echo "Starting MongoDB service..."
sudo systemctl start mongod

# Install Node.js
echo "Installing Node.js..."
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update -y
sudo apt install nodejs -y
sudo apt-get install build-essential -y

# Install PM2
echo "Installing PM2..."
sudo npm install -g pm2

# Install Certbot and SSL library
echo "Installing Certbot for SSL configuration..."
sudo apt install certbot python3-certbot-nginx -y

# Install and configure Redis
echo "Installing Redis server..."
sudo apt install redis-server -y
sudo sed -i "/^# requirepass/ s/^# //; s/requirepass .*/requirepass $redis_password/" /etc/redis/redis.conf
sudo systemctl restart redis.service

# Configure Nginx
echo "Configuring Nginx..."
sudo rm -rf /etc/nginx/sites-available/default
sudo rm -rf /etc/nginx/sites-enabled/default

# Create required directories
echo "Creating required directories..."
sudo mkdir -p /efs/project-build
sudo chmod -R 777 /efs

# Copy views folder to project-build
if [ -d "$views_path" ]; then
  sudo cp -r "$views_path" /efs/project-build
else
  echo "The specified path for the 'views' folder does not exist. Please check the path and try again."
  exit 1
fi

# Additional folders with permissions
sudo mkdir -p /tmp/thumbnail /mnt/fileUploads
sudo chmod 777 -R /mnt

# MongoDB Dump Restore
if [ -d "$project_folder" ]; then
  echo "Restoring MongoDB dump from $project_folder/dump folder..."
  cd "$project_folder"
  mongorestore
else
  echo "The specified path for the main project folder does not exist. Please check the path and try again."
  exit 1
fi

# Update .env files in exchange-engine and exchange-surface with Redis and project folder details
update_env_file() {
  local env_file=$1
  sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|" "$env_file"
  sed -i "s|REDIS_PORT=.*|REDIS_PORT=6379|" "$env_file"
  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_password|" "$env_file"
  sed -i "s|BUILD_FOLDER=.*|BUILD_FOLDER=$project_folder|" "$env_file"
}

echo "Updating .env files in exchange-engine and exchange-surface directories..."
if [ -f "$project_folder/exchange-engine/.env" ]; then
  update_env_file "$project_folder/exchange-engine/.env"
else
  echo "Warning: .env file not found in exchange-engine directory."
fi

if [ -f "$project_folder/exchange-surface/.env" ]; then
  update_env_file "$project_folder/exchange-surface/.env"
else
  echo "Warning: .env file not found in exchange-surface directory."
fi

echo "Setup completed successfully!"
