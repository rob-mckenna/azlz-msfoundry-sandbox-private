#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="infrastructure/terraform"

echo -e "${YELLOW}Terraform Cleanup${NC}"
echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

cd "$TERRAFORM_DIR" || exit 1

# Destroy infrastructure
echo -e "${YELLOW}Destroying Terraform infrastructure...${NC}"
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Infrastructure destroyed${NC}"
else
    echo -e "${RED}Terraform destroy failed${NC}"
    exit 1
fi
