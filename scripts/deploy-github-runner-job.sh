#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${REPO_ROOT}/infrastructure/terraform"

RESOURCE_GROUP="${RESOURCE_GROUP:-azlz-dev-rg}"
ACR_NAME="${ACR_NAME:-azlzacr2cbd}"
RUNNER_IMAGE_NAME="${RUNNER_IMAGE_NAME:-github-actions-runner}"
RUNNER_IMAGE_TAG="${RUNNER_IMAGE_TAG:-1.0}"
GITHUB_REPO="${GITHUB_REPO:-rob-mckenna/azlz-msfoundry-sandbox-private}"

RUNNER_IMAGE="${ACR_NAME}.azurecr.io/${RUNNER_IMAGE_NAME}:${RUNNER_IMAGE_TAG}"
GITHUB_REPO_URL="https://github.com/${GITHUB_REPO}"

echo -e "${YELLOW}==> Validating prerequisites${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI not found${NC}"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo -e "${RED}GitHub CLI not found${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found${NC}"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform not found${NC}"; exit 1; }

echo -e "${YELLOW}==> Building runner image from tutorial source${NC}"
docker build \
  -f Dockerfile.github \
  -t "${RUNNER_IMAGE}" \
  "https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial.git"

echo -e "${YELLOW}==> Logging into ACR and pushing image${NC}"
az acr login --name "${ACR_NAME}"
docker push "${RUNNER_IMAGE}"

echo -e "${YELLOW}==> Getting GitHub PAT from gh auth session${NC}"
GITHUB_PAT="$(gh auth token)"

if [ -z "${GITHUB_PAT}" ]; then
  echo -e "${RED}Failed to obtain GitHub PAT from gh auth token${NC}"
  exit 1
fi

echo -e "${YELLOW}==> Deploying runner job with Terraform${NC}"
pushd "${TERRAFORM_DIR}" >/dev/null

export TF_VAR_github_runner_url="${GITHUB_REPO_URL}"
export TF_VAR_runner_container_image="${RUNNER_IMAGE}"

terraform validate
terraform apply \
  -target=azurerm_container_app_job.github_runner[0] \
  -var="github_runner_registration_token=${GITHUB_PAT}" \
  -var="github_runner_url=${GITHUB_REPO_URL}" \
  -var="runner_container_image=${RUNNER_IMAGE}" \
  -auto-approve

popd >/dev/null

echo -e "${YELLOW}==> Verifying runner job in Azure Container Apps${NC}"
az containerapp job show \
  --name azlz-runner \
  --resource-group "${RESOURCE_GROUP}" \
  --query "{name:name,provisioning:properties.provisioningState,trigger:properties.configuration.triggerType}" \
  -o table

az containerapp job execution list \
  --name azlz-runner \
  --resource-group "${RESOURCE_GROUP}" \
  --query "[].{Status:properties.status,Name:name,StartTime:properties.startTime}" \
  -o table

echo -e "${GREEN}Runner deployment flow completed.${NC}"
echo -e "${GREEN}Runner image: ${RUNNER_IMAGE}${NC}"
echo -e "${GREEN}Next: trigger a workflow with runs-on: self-hosted and re-run the execution list command.${NC}"
