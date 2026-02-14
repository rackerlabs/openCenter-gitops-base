# S6: Observability (OpenTelemetry + ClickHouse + Grafana) Evidence Pack

## Scope Summary

Analyzed observability stack architecture, instrumentation, data pipelines, and operational practices. Focus on:
- Metrics collection (Prometheus)
- Log aggregation (Loki)
- Distributed tracing (Tempo)
- Unified telemetry (OpenTelemetry)
- Visualization (Grafana)
- Alerting and runbooks

## Evidence Index

**Primary Sources:**
1. `applications/base/services/observability/kube-prometheus-stack/README.md`
2. `applications/base/services/observability/loki/README.md`
3. `applications/base/services/observability/tempo/README.md`
4. `applications/base/services/observability/opentelemetry-kube-stack/README.md`
5. `applications/base/services/observability/mimir/README.md`
6. `docs/service-standards-and-lifecycle.md` - Observability requirements (lines 56-60)
7. `README.md` - Observability stack overview (lines 62-80)

## Repo-Derived Facts

### Four-Component Observability Stack
**Evidence:** Complete metrics/logs/traces solution
- **Citation:** `README.md` lines 62-80
- **Components:**
  1. **kube-prometheus-stack** - Prometheus, Alertmanager, Grafana
  2. **loki** - Log aggregation
  3. **tempo** - Distributed tracing
  4. **opentelemetry-kube-stack** - Unified telemetry collection
- **Namespace:** `observability`
- **Fact:** All components in single namespace for integration

### Kube-Prometheus-Stack
**Evidence:** Comprehensive monitoring solution
- **Citation:** `kube-prometheus-stack/README.md`
- **Includes:**
  - Prometheus Operator
  - Prometheus server
  - Alertmanager
  - Grafana with preconfigured dashboards
  - Node exporter, kube-state-metrics
- **Discovery:** ServiceMonitor and PodMonitor CRDs
- **Features:**
  - Custom alerting rules
  - Recording rules
  - Remote write support
- **Dashboards:** Nodes, pods, networking, applications

### Loki Log Aggregation
**Evidence:** Cost-effective log storage
- **Citation:** `loki/README.md`
- **Architecture:** Simple Scalable mode (read/write separation)
- **Integration:** OpenTelemetry OTLP protocol
- **Indexing:** Metadata only (not full-text)
- **Query:** LogQL (similar to PromQL)
- **Features:**
  - Multi-tenancy
  - Retention policies
  - Compaction
- **Storage:** Object storage backend
- **Fact:** Lower cost than traditional log solutions

### Tempo Distributed Tracing
**Evidence:** Scalable trace backend
- **Citation:** `tempo/README.md`
- **Architecture:** Distributed mode (read/write separation)
- **Integration:** OpenTelemetry OTLP protocol
- **Storage:** Object storage (not databases)
- **WAL:** Write-Ahead Log for durability
- **Format:** Parquet blocks for long-term retention
- **Query:** TraceQL for trace analysis
- **Fact:** Cost-effective trace storage

### OpenTelemetry Kube Stack
**Evidence:** Unified telemetry framework
- **Citation:** `opentelemetry-kube-stack/README.md`
- **Operator:** Manages collectors and instrumentation
- **Collection:**
  - Kubernetes system components
  - Application workloads (SDK or auto-instrumentation)
- **Processing:** Transformation, filtering, batching, enrichment
- **Backends:** Prometheus, Tempo, Loki, Jaeger, OTLP
- **Modes:** Agent and gateway deployment
- **Discovery:** Auto-discovery of K8s workloads

### Mimir for Long-Term Metrics
**Evidence:** Prometheus remote write target
- **Citation:** `applications/base/services/observability/mimir/` directory
- **Purpose:** Long-term metrics storage
- **Fact:** Complements Prometheus for retention

### Observability Requirements
**Evidence:** Mandatory instrumentation standards
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 56-60
- **Required:**
  - Prometheus scrape targets
  - RED/USE metrics (Rate, Errors, Duration / Utilization, Saturation, Errors)
  - Service-level SLIs (availability, latency, error rate)
  - Structured logs (JSON)
  - Correlation IDs
  - OpenTelemetry OTLP exporter (where feasible)
  - Grafana dashboard JSON in repo
  - Alert rules with actionable runbooks

### Grafana Integration
**Evidence:** Unified visualization
- **Citation:** Multiple README files
- **Integration:** Automatic with Prometheus, Loki, Tempo
- **Dashboards:** Preconfigured for infrastructure
- **Correlation:** Metrics, logs, traces in single pane

## Risks & Findings

### CRITICAL: No Dashboards-as-Code Found
- **Severity:** Critical
- **Impact:** Dashboards not version-controlled, manual recreation needed
- **Evidence:** No dashboard JSON files in service directories
- **Root Cause:** Dashboards mentioned but not committed to Git
- **Recommendation:** Export all dashboards to JSON, commit to repo
- **Effort:** 1-2 weeks (all services)
- **Risk:** Dashboard loss, inconsistent monitoring

### HIGH: No Alert Rules Found
- **Severity:** High
- **Impact:** No proactive incident detection
- **Evidence:** No PrometheusRule CRDs in service directories
- **Root Cause:** Alert rules mentioned but not implemented
- **Recommendation:** Create PrometheusRule resources for all services
- **Effort:** 2-3 weeks
- **Risk:** Undetected outages, SLA violations

### HIGH: No Runbooks Found
- **Severity:** High
- **Impact:** Difficult incident response
- **Evidence:** Runbooks mentioned in standards but not found
- **Root Cause:** Documentation gap
- **Recommendation:** Create runbooks for common incidents
- **Effort:** 2-3 weeks
- **Risk:** Extended MTTR, knowledge silos

### HIGH: No SLO Definitions
- **Severity:** High
- **Impact:** No objective reliability targets
- **Evidence:** SLOs mentioned but not defined
- **Recommendation:** Define SLOs for all platform services
- **Effort:** 1-2 weeks
- **Risk:** Unclear reliability expectations

### MEDIUM: No ClickHouse Integration
- **Severity:** Medium
- **Impact:** Missing from original requirements
- **Evidence:** ClickHouse mentioned in task but not in repo
- **Root Cause:** Possible future integration or misunderstanding
- **Recommendation:** Clarify ClickHouse role or remove from requirements
- **Effort:** N/A (clarification)
- **Risk:** Confusion about architecture

### MEDIUM: No Retention Policies Visible
- **Severity:** Medium
- **Impact:** Unclear data retention, potential cost issues
- **Evidence:** Retention mentioned but not configured
- **Recommendation:** Document retention policies for metrics/logs/traces
- **Effort:** 1-2 days
- **Risk:** Excessive storage costs or data loss

### MEDIUM: No Alertmanager Configuration
- **Severity:** Medium
- **Impact:** Alerts may not route correctly
- **Evidence:** Alertmanager included but no routing config found
- **Recommendation:** Configure Alertmanager routes and receivers
- **Effort:** 1-2 days
- **Risk:** Missed alerts, alert fatigue

### LOW: No Synthetic Monitoring
- **Severity:** Low
- **Impact:** No proactive endpoint checks
- **Evidence:** Blackbox exporter not found
- **Recommendation:** Add blackbox exporter for synthetic checks
- **Effort:** 1 week
- **Risk:** Undetected external-facing issues

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Set Up Complete Observability for Your First Service"
- "Create Your First Grafana Dashboard"
- "Configure Prometheus Alerts with Runbooks"

### How-to Topics
- "Add ServiceMonitor for Prometheus Scraping"
- "Configure Loki Log Shipping with OpenTelemetry"
- "Enable Distributed Tracing with Tempo"
- "Create Custom Grafana Dashboards"
- "Define SLOs and Error Budgets"
- "Configure Alertmanager Routing"
- "Export Dashboards to Git"
- "Query Logs with LogQL"
- "Query Traces with TraceQL"
- "Troubleshoot Missing Metrics"

### Reference Topics
- **Prometheus Configuration Reference**
  - ServiceMonitor, PodMonitor specs
  - PrometheusRule format
  - Recording rules
  - Remote write configuration
- **Loki Configuration Reference**
  - OTLP receiver settings
  - Retention policies
  - LogQL syntax
- **Tempo Configuration Reference**
  - OTLP receiver settings
  - Storage configuration
  - TraceQL syntax
- **OpenTelemetry Configuration Reference**
  - Collector modes (agent, gateway)
  - Processor pipelines
  - Exporter configurations
- **Grafana Dashboards Reference**
  - Dashboard JSON structure
  - Variable syntax
  - Panel types

### Explanation Topics
- "Observability Stack Architecture"
- "Why OpenTelemetry for Unified Telemetry"
- "Cost-Effective Log Storage with Loki"
- "Distributed Tracing Fundamentals"
- "SLO-Based Alerting Strategy"

## Unknowns + VERIFY Steps

1. **Dashboard Storage**
   - **Unknown:** Are dashboards stored in ConfigMaps?
   - **VERIFY:** Check for Grafana dashboard ConfigMaps
   - **Expected:** Dashboard provisioning via ConfigMaps

2. **Alert Rules Location**
   - **Unknown:** Are alert rules in Helm values?
   - **VERIFY:** Sample Helm values files
   - **Expected:** PrometheusRule resources

3. **Retention Configuration**
   - **Unknown:** What are retention periods?
   - **VERIFY:** Check Prometheus, Loki, Tempo configs
   - **Expected:** 15d metrics, 30d logs, 7d traces (typical)

4. **Remote Write Targets**
   - **Unknown:** Is Prometheus writing to Mimir?
   - **VERIFY:** Check Prometheus remote write config
   - **Expected:** Mimir endpoint configured

5. **Alertmanager Receivers**
   - **Unknown:** Where do alerts go?
   - **VERIFY:** Check Alertmanager config
   - **Expected:** Slack, PagerDuty, email

6. **OpenTelemetry Pipelines**
   - **Unknown:** What processors are configured?
   - **VERIFY:** Check OTel Collector config
   - **Expected:** Batch, memory_limiter, resource detection

7. **Grafana Data Sources**
   - **Unknown:** Are data sources provisioned?
   - **VERIFY:** Check Grafana provisioning configs
   - **Expected:** Prometheus, Loki, Tempo auto-configured

## Cross-Cutting Alerts

- **Operations:** Critical gap in dashboards and alerts
- **Reliability:** No SLOs defined - unclear reliability targets
- **Incident Response:** No runbooks - extended MTTR
- **Cost:** Retention policies not visible - potential cost issues
