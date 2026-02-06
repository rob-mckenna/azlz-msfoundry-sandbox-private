#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="infrastructure/terraform"

echo -e "${YELLOW}Terraform Planning${NC}"

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

# Create plan
echo -e "${YELLOW}Creating Terraform plan...${NC}"
terraform plan -out=tfplan

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Plan created successfully: tfplan${NC}"
    echo -e "${GREEN}Review the plan and run: terraform apply tfplan${NC}"
else
    echo -e "${RED}Terraform plan failed${NC}"
    exit 1
fi
