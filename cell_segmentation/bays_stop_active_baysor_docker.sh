#!/bin/bash

# Check if the container is running
if sudo docker ps -q --filter "name=baysor_docker" 2>/dev/null; then
    # Container is running, stop and remove it
    echo "Stopping and removing the 'baysor_docker' container..."
    sudo docker stop baysor_docker
    sudo docker rm baysor_docker
    echo "Container 'baysor_docker' stopped and removed."
else
    echo "No running container with the name 'baysor_docker' found."
fi
