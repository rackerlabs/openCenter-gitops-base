---
id: [service-name]-standards
title: [Service Name] Standards & Lifecycle
sidebar_label: [Service Name] Standards
description: Standards for [service description] in the openCenter platform.
tags: [developer, operators, service, standards, lifecycle, [service-name]]
audience: [Developer, Operations]
---

# [Service Name] Standards & Lifecycle

> **Purpose.** [Brief description of the service's purpose and role in the platform]
>
> **Scope.** [Define what this service covers and its boundaries]

---

## 0) Service Intake Workflow

1. **Intake Request:** [Service-specific intake requirements]
2. **Architecture Review:** [Architecture considerations specific to this service]
3. **Prototype in Dev:** [Development requirements and deliverables]
4. **Operational Review:** [Operational validation requirements]
5. **Stage Decision:** [Decision criteria and approval process]

---

## 1) Service Requirements (Authoritative Checklist)

### 1.1 Functional & Delivery

* [ ] **[Requirement 1]:** [Description and acceptance criteria]
* [ ] **[Requirement 2]:** [Description and acceptance criteria]
* [ ] **[Requirement 3]:** [Description and acceptance criteria]

### 1.2 Security & Compliance (Minimum)

* [ ] **[Security Requirement 1]:** [Description and compliance mapping]
* [ ] **[Security Requirement 2]:** [Description and compliance mapping]
* [ ] **[Security Requirement 3]:** [Description and compliance mapping]

### 1.3 Observability (Minimum)

* [ ] **[Observability Requirement 1]:** [Metrics, logs, traces requirements]
* [ ] **[Observability Requirement 2]:** [Dashboard and alerting requirements]
* [ ] **[Observability Requirement 3]:** [SLI/SLO requirements]

### 1.4 Operations & Support

* [ ] **[Operations Requirement 1]:** [Documentation requirements]
* [ ] **[Operations Requirement 2]:** [Runbook requirements]
* [ ] **[Operations Requirement 3]:** [Support model requirements]

### 1.5 Implementation Guidance

- **[Guidance Area 1]:** [Specific implementation guidance]
- **[Guidance Area 2]:** [Best practices and recommendations]
- **[Guidance Area 3]:** [Common patterns and approaches]

#### Sample Configuration

```yaml
[example configuration relevant to this service]
```

#### Common Pitfalls

- [Common mistake 1 and how to avoid it]
- [Common mistake 2 and how to avoid it]
- [Common mistake 3 and how to avoid it]

---

## 2) Project Risk Assessment

Create `RISK.md` capturing the following for [Service Name]:

| Factor                 | Score | Notes                           |
| ---------------------- | ----- | ------------------------------- |
| **[Risk Factor 1]**    | [1-5] | [Service-specific considerations] |
| **[Risk Factor 2]**    | [1-5] | [Service-specific considerations] |
| **[Risk Factor 3]**    | [1-5] | [Service-specific considerations] |

**Risk Score:** [Calculated score and tier]

**Additional Considerations:**
- [Service-specific risk factors]
- [Mitigation strategies]
- [Compensating controls]

---

## 3) Architecture & Configuration

### 3.1 Service Architecture

```
[Architecture diagram or description]
```

### 3.2 Configuration Principles

- **[Principle 1]:** [Description and rationale]
- **[Principle 2]:** [Description and rationale]
- **[Principle 3]:** [Description and rationale]

### 3.3 Example Configuration

```yaml
[Service-specific configuration example]
```

### 3.4 Dependencies

- **[Dependency 1]:** [Description and requirements]
- **[Dependency 2]:** [Description and requirements]
- **[Dependency 3]:** [Description and requirements]

---

## 4) Deployment & Scheduling

### 4.1 Node Selection Strategy

```yaml
[Service-specific tolerations and node selectors]
```

### 4.2 Resource Requirements

- **CPU:** [Requirements and limits]
- **Memory:** [Requirements and limits]
- **Storage:** [Requirements and characteristics]

### 4.3 Scaling Considerations

- **Horizontal Scaling:** [HPA configuration and limits]
- **Vertical Scaling:** [VPA considerations]
- **Storage Scaling:** [Volume expansion capabilities]

---

## 5) Service Labels & Metadata

### 5.1 Required Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: [service-name]
    app.kubernetes.io/instance: [instance-name]
    app.kubernetes.io/version: [version]
    app.kubernetes.io/component: [component]
    app.kubernetes.io/part-of: [system]
    app.kubernetes.io/managed-by: fluxcd
    opencenter.io/owner: [team-email]
    opencenter.io/tier: [platform|shared|tenant]
    opencenter.io/data-sensitivity: [classification]
    opencenter.io/rto: [recovery-time]
    opencenter.io/rpo: [recovery-point]
    opencenter.io/sla: [availability-target]
    opencenter.io/backup-profile: [backup-schedule]
```

### 5.2 Service-Specific Labels

- **[Custom Label 1]:** [Purpose and values]
- **[Custom Label 2]:** [Purpose and values]
- **[Custom Label 3]:** [Purpose and values]

---

## 6) Production Requirements

### 6.1 Documentation Bundle

- **README.md:** [Service overview and quick start]
- **OPERATIONS.md:** [Operational procedures]
- **TROUBLESHOOTING.md:** [Common issues and solutions]
- **SLO.md:** [Service level objectives and indicators]

### 6.2 Observability Requirements

- **Metrics:** [Required metrics and collection]
- **Dashboards:** [Grafana dashboard requirements]
- **Alerts:** [Alert rules and thresholds]
- **Logs:** [Logging requirements and retention]

### 6.3 Backup & Recovery

- **Backup Strategy:** [What needs to be backed up]
- **Recovery Procedures:** [Step-by-step recovery process]
- **Testing:** [Backup/recovery testing schedule]

---

## 7) Preview Service Considerations

- **Preview Scope:** [What functionality is available in preview]
- **Limitations:** [Known limitations and workarounds]
- **Success Criteria:** [Metrics for graduation to production]
- **Timeline:** [Expected preview duration and milestones]

---

## 8) Service Lifecycle Gates

| Stage      | Entry Criteria                    | Exit Criteria                     |
| ---------- | --------------------------------- | --------------------------------- |
| Incubating | [Service-specific entry criteria] | [Service-specific exit criteria]  |
| Preview    | [Service-specific entry criteria] | [Service-specific exit criteria]  |
| Production | [Service-specific entry criteria] | [Service-specific exit criteria]  |
| Deprecated | [Service-specific entry criteria] | [Service-specific exit criteria]  |
| Retired    | [Service-specific entry criteria] | [Service-specific exit criteria]  |

### Stage-Specific Deliverables

- **Incubating:** [Required deliverables]
- **Preview:** [Required deliverables]
- **Production:** [Required deliverables]
- **Deprecated:** [Required deliverables]
- **Retired:** [Required deliverables]

---

## 9) Testing & Validation

### 9.1 Test Strategy

- **Unit Tests:** [Coverage requirements and scope]
- **Integration Tests:** [Test scenarios and dependencies]
- **End-to-End Tests:** [User journey validation]
- **Performance Tests:** [Load and stress testing]

### 9.2 Validation Pipeline

```yaml
[CI/CD pipeline configuration specific to this service]
```

### 9.3 Quality Gates

- **Code Quality:** [Linting, formatting, complexity thresholds]
- **Security:** [SAST, dependency scanning, image scanning]
- **Performance:** [Latency, throughput, resource usage thresholds]

---

## 10) Operational Procedures

### 10.1 Deployment Procedures

1. **Pre-deployment:** [Checklist and validation steps]
2. **Deployment:** [Step-by-step deployment process]
3. **Post-deployment:** [Verification and rollback procedures]

### 10.2 Maintenance Procedures

- **Regular Maintenance:** [Scheduled maintenance tasks]
- **Updates:** [Update procedures and testing]
- **Monitoring:** [Ongoing monitoring requirements]

### 10.3 Incident Response

- **Escalation Path:** [Who to contact and when]
- **Common Incidents:** [Typical issues and responses]
- **Recovery Procedures:** [Step-by-step recovery actions]

---

## 11) Compliance & Security

### 11.1 Compliance Mapping

| Control | Requirement | Implementation | Evidence |
| ------- | ----------- | -------------- | -------- |
| [Control ID] | [Requirement description] | [How it's implemented] | [Evidence location] |

### 11.2 Security Controls

- **Authentication:** [How users/services authenticate]
- **Authorization:** [RBAC and access controls]
- **Encryption:** [Data in transit and at rest]
- **Audit:** [Logging and audit trail requirements]

---

## 12) Appendices

### 12.1 Configuration Examples

[Additional configuration examples and templates]

### 12.2 Troubleshooting Guide

[Detailed troubleshooting procedures and common solutions]

### 12.3 Reference Documentation

- [Link to upstream documentation]
- [Link to related ADRs]
- [Link to runbooks]
- [Link to dashboards]