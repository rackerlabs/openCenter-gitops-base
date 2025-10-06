# Zalando Postgres Operator – Base Configuration

This directory contains the **base manifests** for deploying the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator), a Kubernetes operator that automates the management of PostgreSQL clusters.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Zalando Postgres Operator:**

- Automates the **provisioning, scaling, and maintenance** of PostgreSQL database clusters on Kubernetes.  
- Manages **Postgres instances, replicas, and failover** automatically to ensure high availability.  
- Supports **rolling updates**, **configuration changes**, and **PostgreSQL version upgrades** with minimal downtime.
- Exposes declarative APIs (`postgresql` custom resources) to define database clusters and configurations.  
- Integrates seamlessly with applications such as **Keycloak** or other services requiring external databases.  
- Commonly used in production-grade environments for managing secure and self-healing PostgreSQL clusters.  
- Simplifies database lifecycle management and reduces operational overhead in cloud-native environments.  
