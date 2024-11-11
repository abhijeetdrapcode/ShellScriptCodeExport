#!/bin/bash

# Function to remove MongoDB
uninstall_mongodb() {
    echo "Uninstalling MongoDB..."

    # Stop MongoDB service
    sudo systemctl stop mongod

    # Remove MongoDB packages
    sudo apt-get purge mongodb-org* -y

    # Remove MongoDB related files (optional)
    sudo rm -rf /var/log/mongodb
    sudo rm -rf /var/lib/mongodb
    sudo rm -rf /etc/mongodb.conf

    # Remove unused dependencies
    sudo apt-get autoremove -y

    # Clean up
    sudo apt-get autoclean -y
    echo "MongoDB has been uninstalled."
}

# Function to remove Nginx
uninstall_nginx() {
    echo "Uninstalling Nginx..."

    # Stop Nginx service
    sudo systemctl stop nginx

    # Uninstall Nginx
    sudo apt-get purge nginx nginx-common nginx-full -y

    # Remove Nginx related directories (optional)
    sudo rm -rf /etc/nginx
    sudo rm -rf /var/www/html

    # Remove unused dependencies
    sudo apt-get autoremove -y

    # Clean up
    sudo apt-get autoclean -y
    echo "Nginx has been uninstalled."
}

# Function to remove PM2
uninstall_pm2() {
    echo "Uninstalling PM2..."

    # Stop all PM2 processes
    pm2 stop all

    # Uninstall PM2 globally
    sudo npm uninstall -g pm2

    # Clean up PM2's log and data files (optional)
    sudo rm -rf ~/.pm2

    echo "PM2 has been uninstalled."
}

# Function to remove Redis
uninstall_redis() {
    echo "Uninstalling Redis..."

    # Stop Redis service
    sudo systemctl stop redis

    # Uninstall Redis
    sudo apt-get purge redis-server -y

    # Remove Redis related directories (optional)
    sudo rm -rf /var/lib/redis
    sudo rm -rf /etc/redis

    # Remove unused dependencies
    sudo apt-get autoremove -y

    # Clean up
    sudo apt-get autoclean -y
    echo "Redis has been uninstalled."
}

# Function to remove Node.js
uninstall_nodejs() {
    echo "Uninstalling Node.js..."

    # Remove Node.js
    sudo apt-get purge nodejs -y

    # Remove global npm packages (optional)
    sudo rm -rf /usr/local/lib/node_modules

    # Remove Node.js configuration files
    sudo rm -rf ~/.npm
    sudo rm -rf ~/.node
    sudo rm -rf ~/.nvm  # Only if using NVM

    # Remove unused dependencies
    sudo apt-get autoremove -y

    # Clean up
    sudo apt-get autoclean -y
    echo "Node.js has been uninstalled."
}

# Main function to uninstall everything
uninstall_all() {
    uninstall_mongodb
    uninstall_nginx
    uninstall_pm2
    uninstall_redis
    uninstall_nodejs

    echo "All specified software has been uninstalled."
}

# Run the uninstallation
uninstall_all
