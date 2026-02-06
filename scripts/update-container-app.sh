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
RESOURCE_GROUP="${3:-azlz-rg}"
CONTAINER_APP_NAME="${4:-azlz-app}"

if [ -z "$ACR_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${RED}Error: Required parameters missing${NC}"
    echo "Usage: ./update-container-app.sh <acr-name> [image-name] [resource-group] [app-name]"
    exit 1
fi

ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
IMAGE_URI="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"

echo -e "${YELLOW}Updating Container App: ${CONTAINER_APP_NAME}${NC}"
echo -e "${YELLOW}Image: ${IMAGE_URI}${NC}"

# Update the Container App with the new image
az containerapp update \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --image "${IMAGE_URI}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Container app updated successfully${NC}"
else
    echo -e "${RED}Failed to update container app${NC}"
    exit 1
fi

# Get the FQDN
echo -e "${YELLOW}Retrieving Container App URL...${NC}"
FQDN=$(az containerapp show \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

if [ -n "$FQDN" ]; then
    echo -e "${GREEN}Container App URL: https://${FQDN}${NC}"
else
    echo -e "${RED}Could not retrieve Container App URL${NC}"
fi
