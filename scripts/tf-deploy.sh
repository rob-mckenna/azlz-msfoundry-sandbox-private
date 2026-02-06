#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="infrastructure/terraform"

echo -e "${YELLOW}Terraform Deployment${NC}"

cd "$TERRAFORM_DIR" || exit 1

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform init failed${NC}"
    exit 1
fi

# Validate configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Validation successful${NC}"

# Apply configuration
echo -e "${YELLOW}Applying Terraform configuration...${NC}"
terraform apply -auto-approve

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Terraform deployment successful!${NC}"
    echo -e "${GREEN}Getting deployment outputs...${NC}"
    terraform output
else
    echo -e "${RED}Terraform apply failed${NC}"
    exit 1
fi
