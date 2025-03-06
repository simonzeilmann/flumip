#!/bin/bash

# Check if the process name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <process_name>"
  exit 2
fi

PROCESS_NAME=$1

# Function to handle errors
function handle_error {
  echo "An error occurred. Exiting."
  exit 3
}

# Trap any errors and call the handle_error function
trap 'handle_error' ERR

# Check if the process is running
pgrep -f "$PROCESS_NAME"
if [ $? -eq 0 ]; then
  # If the process is running, kill it
  kill -9 $(pgrep -f "$PROCESS_NAME")
  exit 0
else
  echo "Process not running"
  exit 1
fi