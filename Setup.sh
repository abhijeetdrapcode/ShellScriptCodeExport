#!/bin/bash

# Function to prompt the user for input
prompt_user() {
    local prompt_message="$1"
    local user_input
    read -p "$prompt_message: " user_input
    echo "$user_input"
}

# Function to check if a package is installed and get its version
check_installed_version() {
    local package_name="$1"
    if command -v $package_name >/dev/null 2>&1; then
        local version=$($package_name --version | grep -oP '\d+(\.\d+)+')
        echo "$version"
    else
        echo "not installed"
    fi
}

# Update System
echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install ubuntu-restricted-extras -y

# Install essential libraries
echo "Installing essential libraries..."
sudo apt install unzip zip -y

# NGINX Setup and Version Check
nginx_version=$(check_installed_version nginx)
if [[ "$nginx_version" != "not installed" ]]; then
    echo "NGINX is already installed, version: $nginx_version"
    read -p "Do you want to update NGINX? (y/n): " update_nginx
    if [[ "$update_nginx" == "y" ]]; then
        sudo apt install nginx -y
    fi
else
    echo "Installing NGINX..."
    sudo apt install nginx -y
fi

# Install libraries for MongoDB
echo "Checking MongoDB dependencies..."
sudo apt-get install libatk1.0-0 libnss3 libxss1 libasound2 libatk-bridge2.0-0 libgtk-3-0 -y

# MongoDB Setup and Version Check
mongodb_version=$(check_installed_version mongod)
if [[ "$mongodb_version" != "not installed" ]]; then
    echo "MongoDB is already installed, version: $mongodb_version"
    read -p "Do you want to update MongoDB? (y/n): " update_mongodb
    if [[ "$update_mongodb" == "y" ]]; then
        echo "Installing MongoDB..."
        wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
        sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
        sudo apt-get update -y
        sudo apt-get install -y mongodb-org
        sudo systemctl start mongod
    fi
else
    echo "Installing MongoDB..."
    # MongoDB installation commands here if it's not installed
fi

# Install Node.js using Nodesource
node_version=$(check_installed_version node)
if [[ "$node_version" != "not installed" ]]; then
    echo "Node.js is already installed, version: $node_version"
    read -p "Do you want to update Node.js? (y/n): " update_node
    if [[ "$update_node" == "y" ]]; then
        echo "Updating Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo apt-get install build-essential -y
    fi
else
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo apt-get install build-essential -y
fi

# Install or Update PM2
if command -v pm2 >/dev/null 2>&1; then
    echo "PM2 is already installed."
    read -p "Do you want to update PM2? (y/n): " update_pm2
    if [[ "$update_pm2" == "y" ]]; then
        sudo npm install -g pm2
    fi
else
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# SSL library
if command -v certbot >/dev/null 2>&1; then
    echo "Certbot is already installed."
else
    echo "Installing SSL library..."
    sudo apt install certbot python3-certbot-nginx -y
fi

# Redis Setup and Version Check
redis_version=$(check_installed_version redis-server)
if [[ "$redis_version" != "not installed" ]]; then
    echo "Redis is already installed, version: $redis_version"
    read -p "Do you want to update Redis? (y/n): " update_redis
    if [[ "$update_redis" == "y" ]]; then
        sudo apt install redis-server -y
    fi
else
    echo "Installing Redis..."
    sudo apt install redis-server -y
fi

# Configure Redis password
redis_password=$(prompt_user "Enter Redis password")
sudo sed -i "/^# requirepass /c\requirepass $redis_password" /etc/redis/redis.conf
sudo systemctl restart redis.service

# Ask for main folder location and copy Nginx configuration
main_folder=$(prompt_user "Enter the path to the main folder (containing .env files and shell scripts)")
readme_location="$main_folder/README"
nginx_config_path="/etc/nginx/sites-available/custom-domain.conf"
grep -A 1000 "#### BELOW THIS LINE ####" "$readme_location" > "$nginx_config_path"
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s "$nginx_config_path" /etc/nginx/sites-enabled/

# Generate SSL certificates
sudo certbot --nginx -d codeexport.drapcode.us
sudo certbot --nginx -d codeexportapi.drapcode.us

# Check Nginx configuration and restart
sudo nginx -t && sudo service nginx restart

# Setup directories
echo "Setting up directories..."
sudo mkdir -p /efs/project-build /tmp/thumbnail /mnt/fileUploads
sudo chmod -R 777 /efs /mnt

# Copy views folder from main folder
views_folder="$main_folder/views"
sudo cp -r "$views_folder" /efs/project-build/

# MongoDB Restore
mongo_dump_location=$(prompt_user "Enter the MongoDB dump folder location")
mongorestore "$mongo_dump_location"

# Configure .env files with Redis settings
echo "Configuring environment files..."
engine_env="$main_folder/exchange-engine/.env"
surface_env="$main_folder/exchange-surface/.env"
echo "REDIS_HOST=127.0.0.1" | sudo tee -a "$engine_env" "$surface_env"
echo "REDIS_PORT=6379" | sudo tee -a "$engine_env" "$surface_env"
echo "REDIS_PASSWORD=$redis_password" | sudo tee -a "$engine_env" "$surface_env"

# Run Shell Scripts in Main Folder
echo "Executing shell scripts in $main_folder..."
for script in "$main_folder"/*.sh; do
    if [[ -f "$script" ]]; then
        sudo chmod +x "$script"
        "$script"
    fi
done

echo "Setup completed successfully."
