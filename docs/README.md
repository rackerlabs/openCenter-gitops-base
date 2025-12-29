# OpenCenter Service Configuration Guides

This directory contains comprehensive configuration guides for all services available in the openCenter platform. Each guide provides detailed configuration examples, common pitfalls, troubleshooting steps, and best practices.

## Available Configuration Guides

### Core Infrastructure Services

| Service | Guide | Description |
|---------|-------|-------------|
| **Cert-manager** | [cert-manager-config-guide.md](cert-manager-config-guide.md) | TLS certificate management and automation |
| **Harbor** | [harbor-config-guide.md](harbor-config-guide.md) | Container registry with security scanning |
| **Keycloak** | [keycloak-config-guide.md](keycloak-config-guide.md) | Identity and access management |
| **Kyverno** | [kyverno-config-guide.md](kyverno-config-guide.md) | Kubernetes-native policy engine |
| **Longhorn** | [longhorn-config-guide.md](longhorn-config-guide.md) | Distributed block storage system |
| **MetalLB** | [metallb-config-guide.md](metallb-config-guide.md) | Load balancer for bare-metal clusters |
| **Sealed Secrets** | [sealed-secrets-config-guide.md](sealed-secrets-config-guide.md) | GitOps-friendly secret encryption |
| **Velero** | [velero-config-guide.md](velero-config-guide.md) | Backup and disaster recovery |

### Observability Stack

| Component | Guide | Description |
|-----------|-------|-------------|
| **Kube-Prometheus-Stack** | [kube-prometheus-stack-config-guide.md](kube-prometheus-stack-config-guide.md) | Complete monitoring with Prometheus, Grafana, Alertmanager |
| **Loki** | [loki-config-guide.md](loki-config-guide.md) | Log aggregation and storage system |
| **Tempo** | [tempo-config-guide.md](tempo-config-guide.md) | Distributed tracing backend |
| **OpenTelemetry** | [opentelemetry-kube-stack-config-guide.md](opentelemetry-kube-stack-config-guide.md) | Unified observability data collection |

## Guide Structure

Each configuration guide follows a consistent structure:

### 1. Overview
Brief description of the service and its role in the Kubernetes cluster.

### 2. Key Configuration Choices
Detailed examples of important configuration options with explanations of why specific choices were made.

### 3. Common Pitfalls
Description of frequently encountered issues, their causes, and step-by-step solutions with verification commands.

### 4. Required Secrets
Documentation of all secrets required by the service, including field descriptions and examples.

### 5. Verification
Commands to verify the service is running correctly and functioning as expected.

### 6. Usage Examples
Practical examples of common use cases and configuration patterns.

## Templates

### Service Documentation Templates

| Template | Purpose | Location |
|----------|---------|----------|
| **Service README Template** | Base template for service README files | [templates/service-readme-template.md](templates/service-readme-template.md) |
| **Configuration Guide Template** | Template for detailed configuration guides | [templates/service-config-guide-template.md](templates/service-config-guide-template.md) |
| **Service Standards Template** | Template for service standards documentation | [templates/service-standards-template.md](templates/service-standards-template.md) |

## Getting Started

1. **Choose Your Service**: Select the service you want to configure from the tables above
2. **Read the Configuration Guide**: Follow the detailed configuration examples and explanations
3. **Implement Configuration**: Apply the configurations to your cluster with appropriate customizations
4. **Verify Deployment**: Use the verification steps to ensure the service is working correctly
5. **Troubleshoot Issues**: Refer to the common pitfalls section if you encounter problems

## Best Practices

### Configuration Management
- Use GitOps principles for all configuration changes
- Store sensitive data in encrypted secrets (Sealed Secrets or SOPS)
- Implement proper resource limits and requests
- Follow security best practices for each service

### Monitoring and Observability
- Enable monitoring for all services using the observability stack
- Set up appropriate alerts for service health and performance
- Implement proper logging and tracing for troubleshooting

### Security
- Follow the principle of least privilege for RBAC
- Use network policies to restrict traffic between services
- Regularly update services and scan for vulnerabilities
- Implement proper backup and disaster recovery procedures

### Maintenance
- Regularly review and update configurations
- Test backup and restore procedures
- Monitor resource usage and scale as needed
- Keep documentation up to date with configuration changes

## Contributing

When adding new services or updating existing ones:

1. Use the appropriate template from the `templates/` directory
2. Follow the established structure and formatting
3. Include comprehensive examples and troubleshooting information
4. Test all configuration examples before documenting them
5. Update this README to include the new service

## Support

For service-specific issues:
1. Check the relevant configuration guide for troubleshooting steps
2. Review the service's upstream documentation
3. Check the service logs and Kubernetes events
4. Consult the observability dashboards for metrics and alerts

For platform-wide issues, refer to the main [README](../README.md) and service standards documentation.