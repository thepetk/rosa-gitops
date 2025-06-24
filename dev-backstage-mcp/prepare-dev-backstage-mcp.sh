#!/bin/bash

# Constants
RHDH_NAMESPACE="dev-backstage-mcp"
ARGOCD_NAMESPACE="openshift-gitops"
PAC_NAMESPACE="openshift-pipelines"

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
  "RHDH_CALLBACK_URL" \
  "POSTGRES_USER" \
  "POSTGRES_PASSWORD" \
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
echo "Creating new project for $RHDH_NAMESPACE if it doesn't exist.."
oc new-project $RHDH_NAMESPACE
echo "OK"

# Create the necessary ServiceAccount token
echo "Creating the k8s sa token.."
kubectl create serviceaccount k8s-sa -n $RHDH_NAMESPACE
kubectl create serviceaccount rhdh-sa -n $RHDH_NAMESPACE
kubectl create rolebinding k8s-admin-binding   --clusterrole=admin   --serviceaccount=$RHDH_NAMESPACE:k8s-sa   --namespace=$RHDH_NAMESPACE
K8S_CLUSTER_TOKEN=$(kubectl create token k8s-sa -n $RHDH_NAMESPACE --duration 8760h)
RHDH_SA_TOKEN=$(kubectl create token rhdh-sa -n $RHDH_NAMESPACE)
echo "OK"

##### Create all the secrets necessary for the deployment of RHDH ######
echo "Setting up secrets on $RHDH_NAMESPACE and $PAC_NAMESPACE"
SECRET_NAME="github-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=GITHUB_APP_APP_ID="$GITHUB_APP_APP_ID" \
    --from-literal=GITHUB_APP_CLIENT_ID="$GITHUB_APP_CLIENT_ID" \
    --from-literal=GITHUB_APP_CLIENT_SECRET="$GITHUB_APP_CLIENT_SECRET" \
    --from-literal=GITHUB_APP_WEBHOOK_URL="$GITHUB_APP_WEBHOOK_URL" \
    --from-literal=GITHUB_APP_WEBHOOK_SECRET="$GITHUB_APP_WEBHOOK_SECRET" \
    --from-literal=GITHUB_APP_PRIVATE_KEY="$GITHUB_APP_PRIVATE_KEY" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="kubernetes-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=K8S_CLUSTER_TOKEN="$K8S_CLUSTER_TOKEN" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="postgres-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=POSTGRES_USER="$POSTGRES_USER" \
    --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="quay-pull-secret"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=.dockerconfigjson="$QUAY_DOCKERCONFIGJSON" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="keycloak-secrets"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
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
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=BACKEND_SECRET="$BACKEND_SECRET" \
    --from-literal=ADMIN_TOKEN="$RHDH_SA_TOKEN" \
    --from-literal=RHDH_BASE_URL="$RHDH_BASE_URL" \
    --from-literal=RHDH_CALLBACK_URL="$RHDH_CALLBACK_URL" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"

SECRET_NAME="ai-rh-developer-hub-env"
echo -n "* $SECRET_NAME secret: "
kubectl create secret generic "$SECRET_NAME" \
    --namespace="$RHDH_NAMESPACE" \
    --from-literal=NODE_TLS_REJECT_UNAUTHORIZED="0" \
    --from-literal=RHDH_TOKEN="$RHDH_SA_TOKEN" \
    --dry-run=client -o yaml | kubectl apply --filename - --overwrite=true >/dev/null
echo "OK"