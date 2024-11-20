#!/bin/bash

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "PM2 is not installed. Please install it and try again."
    exit 1
fi

# List running PM2 processes
running_processes=$(pm2 list | grep online)

if [ -z "$running_processes" ]; then
    echo "No PM2 processes are currently running."
else
    # Stop all running processes
    echo "Stopping all PM2 processes..."
    pm2 stop all

    # Confirm stopping
    if [ $? -eq 0 ]; then
        echo "All PM2 processes have been stopped successfully."
    else
        echo "An error occurred while stopping PM2 processes."
    fi
fi
