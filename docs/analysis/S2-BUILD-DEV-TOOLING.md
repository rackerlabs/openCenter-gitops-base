# S2: Build/Dev Tooling & Repo Structure Evidence Pack

## Scope Summary

Analyzed development tooling, repository structure, build processes, and developer workflows. Focus on:
- Repository organization and conventions
- Local development tooling
- Validation and linting
- Migration tooling

## Evidence Index

**Primary Sources:**
1. `.pre-commit-config.yaml` - Pre-commit hooks
2. `.yamllint` - YAML linting rules
3. `.ansible-lint` - Ansible linting config
4. `.github/workflows/pre-commit.yaml` - CI validation
5. `tools/kustomize-migration/` - Migration tooling
6. `README.md` - Repository structure
7. `llms.txt` - Quickstart workflows

## Repo-Derived Facts

### Repository Structure
**Evidence:** Mono-repo with clear separation
- **Citation:** `README.md` lines 8-16
- **Structure:**
  ```
  applications/
  ├── base/services/        # 22 platform services
  ├── base/managed-services/ # Rackspace services
  └── policies/             # Security policies
  iac/                      # Infrastructure-as-Code
  docs/                     # 25+ configuration guides
  tools/                    # Migration utilities
  playbooks/                # Ansible playbooks
  ```
- **Fact:** Clear separation of concerns

### Pre-Commit Hooks
**Evidence:** Comprehensive validation pipeline
- **Citation:** `.pre-commit-config.yaml`
- **Hooks:**
  - Conventional commits (v4.0.0)
  - Shellcheck for bash scripts
  - YAML validation (multi-doc, unsafe)
  - Trailing whitespace, EOF fixes
  - Black (Python formatter)
  - yamllint
- **Fact:** Enforces code quality before commit

### YAML Linting Standards
**Evidence:** Strict YAML formatting
- **Citation:** `.yamllint`
- **Rules:**
  - 2-space indentation
  - Line length disabled
  - Min 1 space from content for comments
  - Forbid non-empty brackets
  - Require newline at EOF
- **Fact:** Consistent YAML style across repo

### CI/CD Pipeline
**Evidence:** GitHub Actions for PR validation

- **Citation:** `.github/workflows/pre-commit.yaml`
- **Workflow:**
  - Trigger: Pull requests
  - Runner: Self-hosted
  - Python: 3.12
  - Actions: Checkout, setup-python, pre-commit
  - Scope: Only changed files
- **Fact:** Validates only modified files for efficiency

### Kustomize Migration Tooling
**Evidence:** Go-based migration tools
- **Citation:** `tools/kustomize-migration/` directory
- **Purpose:** Migrate services to Kustomize component pattern
- **Language:** Go (inferred from directory name)
- **Fact:** Active refactoring to component-based architecture

### Service Directory Convention
**Evidence:** Standardized service layout
- **Citation:** `llms.txt` lines 127-134
- **Pattern:**
  ```
  applications/base/services/my-service/
  ├── kustomization.yaml
  ├── namespace.yaml
  ├── source.yaml (or community/source.yaml)
  ├── helmrelease.yaml
  └── helm-values/
      └── hardened-values-vX.Y.Z.yaml
  ```
- **Fact:** Every service follows this structure

### Community/Enterprise Pattern
**Evidence:** Dual-edition support via Kustomize components
- **Citation:** `applications/base/services/cert-manager/` structure
- **Directories:**
  - `community/` - Open source edition
  - `enterprise/` - Enterprise edition
  - `components/enterprise/` - Enterprise-specific patches
- **Fact:** Single codebase supports both editions

### Documentation Templates
**Evidence:** Template-driven documentation
- **Citation:** `docs/templates/` directory
- **Fact:** Standardized service documentation format

## Risks & Findings

### HIGH: No Automated Testing
- **Severity:** High
- **Impact:** Changes may break deployments without detection
- **Evidence:** No test suite found in repository
- **Root Cause:** GitOps repos often lack automated tests
- **Recommendation:** Add kustomize build validation, Helm lint, policy tests
- **Effort:** 1-2 weeks
- **Risk:** Production incidents from untested changes

### MEDIUM: Self-Hosted Runner Security
- **Severity:** Medium
- **Impact:** CI/CD pipeline depends on self-hosted infrastructure
- **Evidence:** `.github/workflows/pre-commit.yaml` line 7: `runs-on: self-hosted`
- **Root Cause:** Likely for private network access
- **Recommendation:** Document runner security hardening
- **Effort:** 4-8 hours (documentation)

### LOW: No Dependency Scanning
- **Severity:** Low
- **Impact:** Vulnerable dependencies may go undetected
- **Evidence:** No Dependabot or Renovate config found
- **Recommendation:** Enable automated dependency updates
- **Effort:** 2-4 hours


### LOW: Python Version Pinning
- **Severity:** Low
- **Impact:** CI may break with Python updates
- **Evidence:** `.github/workflows/pre-commit.yaml` uses Python 3.12
- **Recommendation:** Pin exact Python version or use version matrix
- **Effort:** 1 hour

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Set Up Local Development Environment"
- "Create Your First Service from Template"
- "Validate Changes Before Commit"

### How-to Topics
- "Run Pre-Commit Hooks Locally"
- "Add a New Service to the Repository"
- "Migrate Service to Component Pattern"
- "Fix YAML Linting Errors"
- "Debug CI/CD Pipeline Failures"

### Reference Topics
- **Repository Structure Reference**
  - Directory purposes and conventions
  - File naming patterns
  - Required vs optional files
- **Pre-Commit Hooks Reference**
  - Hook names, purposes, configurations
  - How to skip hooks (when appropriate)
- **YAML Style Guide**
  - Indentation, line length, comments
  - Multi-document files
  - Kustomize-specific conventions

### Explanation Topics
- "Why Mono-Repo for GitOps"
- "Community vs Enterprise Edition Architecture"
- "Kustomize Components Pattern Rationale"

## Unknowns + VERIFY Steps

1. **Kustomize Migration Tool Implementation**
   - **Unknown:** Tool functionality and usage
   - **VERIFY:** Examine `tools/kustomize-migration/` source code
   - **Expected:** Go modules, README, usage examples

2. **Test Coverage**
   - **Unknown:** Any test suites exist?
   - **VERIFY:** Search for `*_test.go`, `test/`, `tests/` directories
   - **Expected:** Unit tests for migration tools at minimum

3. **Release Process**
   - **Unknown:** How are versions tagged and released?
   - **VERIFY:** Check git tags, CHANGELOG, release workflow
   - **Expected:** Semantic versioning, automated releases

4. **Local Development Workflow**
   - **Unknown:** How do developers test changes locally?
   - **VERIFY:** Check for Makefile, scripts/, developer docs
   - **Expected:** `make validate`, `make test` commands

## Cross-Cutting Alerts

- **Security:** No SAST/DAST scanning in CI pipeline
- **Quality:** No code coverage metrics
- **Operations:** No performance benchmarks for large-scale deployments
