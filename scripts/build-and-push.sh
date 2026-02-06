#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ACR_NAME="${1:-}"
IMAGE_NAME="${2:-azlz-app}"
IMAGE_TAG="${3:-latest}"

if [ -z "$ACR_NAME" ]; then
    echo -e "${RED}Error: ACR name not provided${NC}"
    echo "Usage: ./build-and-push.sh <acr-name> [image-name] [image-tag]"
    exit 1
fi

ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
IMAGE_URI="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${YELLOW}Building Docker image: ${IMAGE_URI}${NC}"

# Build the image
docker build -t "${IMAGE_URI}" -f Dockerfile .

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Docker build succeeded${NC}"

# Login to ACR (requires Azure CLI authentication)
echo -e "${YELLOW}Logging in to Azure Container Registry...${NC}"
az acr login --name "${ACR_NAME}"

if [ $? -ne 0 ]; then
    echo -e "${RED}ACR login failed${NC}"
    exit 1
fi

# Push the image
echo -e "${YELLOW}Pushing image to ACR...${NC}"
docker push "${IMAGE_URI}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker push failed${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully pushed image: ${IMAGE_URI}${NC}"
echo -e "${GREEN}Image is ready for deployment to Azure Container Apps${NC}"
