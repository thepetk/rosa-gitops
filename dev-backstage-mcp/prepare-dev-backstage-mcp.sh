#!/bin/bash

# Constants
BACKSTAGE_NAMESPACE="dev-backstage-mcp"

# Source the private env and check if all env vars
# have been set
source ./private-env
ENV_VARS=(
  "GITHUB_APP_APP_ID" \
  "GITHUB_APP_CLIENT_ID" \
  "GITHUB_APP_CLIENT_SECRET" \
  "GITHUB_APP_WEBHOOK_URL" \
  "GITHUB_APP_WEBHOOK_SECRET" \
  "GITHUB_APP_PRIVATE_KEY" \
  "BACKEND_SECRET" \
  "BACKSTAGE_CALLBACK_URL" \
  "QUAY_DOCKERCONFIGJSON" \
  "KEYCLOAK_METADATA_URL" \
  "KEYCLOAK_CLIENT_ID" \
  "KEYCLOAK_REALM" \
  "KEYCLOAK_BASE_URL" \
  "KEYCLOAK_LOGIN_REALM" \
  "KEYCLOAK_CLIENT_SECRET"
)
for ENV_VAR in "${ENV_VARS[@]}"; do
  if [ -z "${!ENV_VAR}" ]; then
    echo "Error: $ENV_VAR is not set. Exiting..."
    exit 1
  fi
done

# Create project if does not exist
echo "Creating new project for $BACKSTAGE_NAMESPACE if it doesn't exist.."
oc new-project $BACKSTAGE_NAMESPACE
echo "OK"

# Create the necessary ServiceAccount token
echo "Creating the backstage admin token.."
kubectl create serviceaccount backstage-sa -n $BACKSTAGE_NAMESPACE
RHDH_SA_TOKEN=$(kubectl create token backstage-sa -n $BACKSTAGE_NAMESPACE)
echo "OK"

##### Create all the secrets necessary for the deployment of backstage ######
echo "Setting up secrets on $BACKSTAGE_NAMESPACE"
SECRET_NAME="github-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$BACKSTAGE_NAMESPACE" \
    --from-literal=GITHUB_APP_APP_ID="$GITHUB_APP_APP_ID" \
    --from-literal=GITHUB_APP_CLIENT_ID="$GITHUB_APP_CLIENT_ID" \
    --from-literal=GITHUB_APP_CLIENT_SECRET="$GITHUB_APP_CLIENT_SECRET" \
    --from-literal=GITHUB_APP_WEBHOOK_URL="$GITHUB_APP_WEBHOOK_URL" \
    --from-literal=GITHUB_APP_WEBHOOK_SECRET="$GITHUB_APP_WEBHOOK_SECRET" \
    --from-literal=GITHUB_APP_PRIVATE_KEY="$GITHUB_APP_PRIVATE_KEY" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="keycloak-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$BACKSTAGE_NAMESPACE" \
    --from-literal=KEYCLOAK_METADATA_URL="$KEYCLOAK_METADATA_URL" \
    --from-literal=KEYCLOAK_CLIENT_ID="$KEYCLOAK_CLIENT_ID" \
    --from-literal=KEYCLOAK_REALM="$KEYCLOAK_REALM" \
    --from-literal=KEYCLOAK_BASE_URL="$KEYCLOAK_BASE_URL" \
    --from-literal=KEYCLOAK_LOGIN_REALM="$KEYCLOAK_LOGIN_REALM" \
    --from-literal=KEYCLOAK_CLIENT_SECRET="$KEYCLOAK_CLIENT_SECRET" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="backstage-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$BACKSTAGE_NAMESPACE" \
    --from-literal=BACKEND_SECRET="$BACKEND_SECRET" \
    --from-literal=ADMIN_TOKEN="$RHDH_SA_TOKEN" \
    --from-literal=BACKSTAGE_BASE_URL="$BACKSTAGE_BASE_URL" \
    --from-literal=BACKSTAGE_CALLBACK_URL="$BACKSTAGE_CALLBACK_URL" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"