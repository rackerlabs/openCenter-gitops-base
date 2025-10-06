# Keycloak – Base Configuration

This directory contains the **base manifests** for deploying [Keycloak](https://www.keycloak.org/), an open-source identity and access management(IAM) solution that provides authentication, authorization, and single sign-on (SSO) capabilities for applications and services.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Keycloak:**

- Provides centralized **user authentication and authorization** for applications and APIs using OpenID Connect (OIDC) and SAML 2.0.  
- Manages **users, roles, groups, and realms** through a web-based admin console or REST API.  
- Supports **federated identity** integration with external identity providers such as Google, GitHub, or Microsoft Entra ID.  
- Offers fine-grained access control through realm, client, and user configurations.  
- Enables **token-based authentication** for Kubernetes and cloud-native workloads.  
- Deployed via **Operator Lifecycle Manager(OLM)**, which automates the installation and lifecycle management of the Keycloak operator and its CRDs.  
- Configured to use an **external PostgreSQL database** managed by the **Zalando Postgres Operator**, ensuring high availability, automated backups, and seamless scaling.  
- Commonly used for securing Kubernetes dashboards, APIs, and internal services with OIDC-based authentication.
