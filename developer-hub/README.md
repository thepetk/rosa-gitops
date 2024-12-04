# developer-hub

This ArgoCD Application deploys an instance of Developer Hub, with a handful of plugins enabled and configured to use Keycloak for authentication.

## Prerequisites

Before deploying this Application, a secret named `secrets-rhdh` in the `developer-hub` namespace must exist, with the following values:

- `ADMIN_TOKEN`: A token to provide access to the RHDH API. Can be any randomly generated string.
- `BACKEND_SECRET`: Can be a randomly generated string
- `KEYCLOAK_BASE_URL`: The base URL for the keycloak instance, should be something like `https://keycloak-rh-sso.apps.domain.com/auth`
- `KEYCLOAK_CLIENT_ID`: The client ID in Keycloak used to manage authentication.
- `KEYCLOAK_CLIENT_SECRET`: The client secret in Keycloak used to manage authentication.
- `KEYCLOAK_LOGIN_REALM`: The login realm used in Keycloak. 
- `KEYCLOAK_METADATA_URL`: The metadata URL for the keycloak instance and realm. Should be something like `${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_LOGIN_REALM}`
- `OLLAMA_TOKEN`: The API key used by RHDH Lightspeed plugin to access the Ollama service on the cluster
- `OLLAMA_URL`: The API URL for the Ollama service 
- `RHDH_CALLBACK_URL`: The OIDC callback URL in RHDH used for authentication.
- `RHDH_BASE_URL`: The BASE URL used for RHDH, for example `https://backstage-developer-hub-developer-hub.apps.domain.com`


 


