#!/bin/bash

set -euxo pipefail

# Get the absolute path of the directory containing this script (docker directory)
SCRIPT_PATH=$(dirname $(realpath "$0"))

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_ROOT=$(realpath "${DIR}/..")
ROS_DISTRO=jazzy
ARCH="$(uname -m | grep -q 'aarch' && echo 'arm64' || echo 'amd64')"

build_docker_image()
{
    # Set a log message for the build process
    LOG="Building Docker image test_project ..."

    # Print the log message using our debug function
    print_debug
    
    # Change to the root of the repository
    cd ${REPO_ROOT}
    docker buildx build --progress=plain --load \
        --platform linux/$ARCH \
        --build-arg USERNAME="$USER" \
        --build-arg ROS_DISTRO="$ROS_DISTRO" \
        --build-arg TARGET=realsense \
        --build-arg REPO_ROOT="$REPO_ROOT" \
        -f "$SCRIPT_PATH/Dockerfile.realsense" \
        -t crresearchplatformdtweu.azurecr.io/librealsense-dev:latest-$ARCH \
        "$REPO_ROOT"


}

# Function to create a shared folder
# This folder will be used to share files between the host and the Docker container
create_shared_folder()
{
    # Check if the directory doesn't exist
    if [ ! -d "$HOME/workspace/ResearchPlatform" ]; then
        # Set a log message for folder creation
        LOG="Creating $HOME/workspace/ResearchPlatform ..."

        # Print the log message
        print_debug

        # Create the directory and its parent directories if they don't exist
        # -p flag creates parent directories as needed
        mkdir -p $HOME/workspace/ResearchPlatform
    fi
}

# Function to print debug messages
# This provides consistent formatting for our log messages
print_debug()
{
    # Print an empty line for readability
    echo ""

    # Print the log message
    echo $LOG

    # Print another empty line for readability
    echo ""
}

push_images_to_registry() {
    local registry="crresearchplatformdtweu.azurecr.io"

    # Define a list of images
    local images=(
        "librealsense-dev:latest-$ARCH"
    )

    # Loop through the list of images and push each one
    for image in "${images[@]}"; do
        docker push "$registry/$image"
    done
}

# Main execution flow

# Create the shared folder that will be mounted in the container
create_shared_folder

# Build the Docker image
build_docker_image

# Push the Docker images to the local registry
push_images_to_registry
