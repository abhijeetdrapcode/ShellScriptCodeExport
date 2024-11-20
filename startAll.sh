#!/bin/bash

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "PM2 is not installed. Please install it and try again."
    exit 1
fi

# List PM2 processes
pm2_status=$(pm2 list | grep -E "stopped|online")

if [ -z "$pm2_status" ]; then
    echo "No PM2 processes found to start."
else
    # Start all PM2 processes
    echo "Starting all PM2 processes..."
    pm2 start all

    # Confirm starting
    if [ $? -eq 0 ]; then
        echo "All PM2 processes have been started successfully."
    else
        echo "An error occurred while starting PM2 processes."
    fi
fi
